# variable "active_frontend_version" {
#   description = "Active Blue-Green frontend version ('blue' or 'green')"
#   type        = string
#   default     = "green"
# }

# # --- 1. PostgreSQL ---
# resource "kubernetes_deployment" "villa_postgres" {
#   metadata { name = "villa-postgres" }
#   spec {
#     replicas = 1
#     selector { match_labels = { app = "villa-postgres" } }
#     template {
#       metadata { labels = { app = "villa-postgres" } }
#       spec {
#         container {
#           name  = "postgres"
#           image = "postgres:15-alpine"
#           port { container_port = 5432 }
#           env {
#             name  = "POSTGRES_DB"
#             value = "villadb"
#           }
#           env {
#             name  = "POSTGRES_USER"
#             value = "villaadmin"
#           }
#           env {
#             name  = "POSTGRES_PASSWORD"
#             value = "villapass123"
#           }
#         }
#       }
#     }
#   }
#   depends_on = [aws_eks_node_group.villa_workers]
# }

# resource "kubernetes_service" "villa_postgres_service" {
#   metadata { name = "villa-postgres-service" }
#   spec {
#     selector = { app = "villa-postgres" }
#     port {
#       port        = 5432
#       target_port = 5432
#     }
#     type = "ClusterIP"
#   }
# }

# # --- 2. ClickHouse ---
# resource "kubernetes_deployment" "clickhouse_server" {
#   metadata { name = "clickhouse-server" }
#   spec {
#     replicas = 1
#     selector { match_labels = { app = "clickhouse-server" } }
#     template {
#       metadata { labels = { app = "clickhouse-server" } }
#       spec {
#         container {
#           name  = "clickhouse"
#           image = "clickhouse/clickhouse-server:latest"
#           port { container_port = 8123 }
#           port { container_port = 9000 }
#           env {
#             name  = "CLICKHOUSE_SKIP_USER_SETUP"
#             value = "1"
#           }
#         }
#       }
#     }
#   }
#   depends_on = [aws_eks_node_group.villa_workers]
# }

# resource "kubernetes_service" "clickhouse_service" {
#   metadata { name = "clickhouse-service" }
#   spec {
#     selector = { app = "clickhouse-server" }
#     port {
#       name        = "http"
#       port        = 8123
#       target_port = 8123
#     }
#     port {
#       name        = "native"
#       port        = 9000
#       target_port = 9000
#     }
#     type = "ClusterIP"
#   }
# }

# # --- 3. Backend Microservices ---
# locals {
#   backend_services = {
#     property-service = "nalin745/property-service:v1"
#     agent-service    = "nalin745/agent-service:v1"
#     enquiry-service  = "nalin745/enquiry-service:v1"
#   }
# }

# resource "kubernetes_deployment" "backend" {
#   for_each = local.backend_services

#   metadata { name = each.key }
#   spec {
#     replicas = 1
#     selector { match_labels = { app = each.key } }
#     template {
#       metadata { labels = { app = each.key } }
#       spec {
#         container {
#           name  = each.key
#           image = each.value
#           port { container_port = 8000 }
#           env {
#             name  = "DATABASE_URL"
#             value = "postgresql://villaadmin:villapass123@villa-postgres-service:5432/villadb"
#           }
#         }
#       }
#     }
#   }
#   depends_on = [kubernetes_service.villa_postgres_service]
# }

# resource "kubernetes_service" "backend_service" {
#   for_each = local.backend_services

#   metadata { name = each.key }
#   spec {
#     selector = { app = each.key }
#     port {
#       port        = 8000
#       target_port = 8000
#     }
#     type = "ClusterIP"
#   }
# }

# # --- 4. Analytics Service (ClusterIP behind ALB) ---
# resource "kubernetes_deployment" "analytics_service" {
#   metadata { name = "analytics-service" }
#   spec {
#     replicas = 1
#     selector { match_labels = { app = "analytics-service" } }
#     template {
#       metadata { labels = { app = "analytics-service" } }
#       spec {
#         container {
#           name  = "analytics"
#           image = "nalin745/villa-analytics-service:v1"
#           port { container_port = 8000 }
#           env {
#             name  = "CLICKHOUSE_HOST"
#             value = "clickhouse-service"
#           }
#           env {
#             name  = "CLICKHOUSE_PORT"
#             value = "8123"
#           }
#         }
#       }
#     }
#   }
#   depends_on = [kubernetes_service.clickhouse_service]
# }

# resource "kubernetes_service" "analytics_service" {
#   metadata { name = "analytics-service" }
#   spec {
#     selector = { app = "analytics-service" }
#     port {
#       port        = 8004
#       target_port = 8000
#     }
#     type = "ClusterIP"
#   }
# }

# # --- 5. Metabase Server (ClusterIP behind ALB) ---
# resource "kubernetes_deployment" "metabase_server" {
#   metadata { name = "metabase-server" }
#   spec {
#     replicas = 1
#     selector { match_labels = { app = "metabase-server" } }
#     template {
#       metadata { labels = { app = "metabase-server" } }
#       spec {
#         container {
#           name  = "metabase"
#           image = "metabase/metabase:latest"
#           port { container_port = 3000 }
#         }
#       }
#     }
#   }
#   depends_on = [kubernetes_service.clickhouse_service]
# }

# resource "kubernetes_service" "metabase_service" {
#   metadata { name = "metabase-service" }
#   spec {
#     selector = { app = "metabase-server" }
#     port {
#       port        = 3000
#       target_port = 3000
#     }
#     type = "ClusterIP"
#   }
# }

# # --- 6. Blue-Green Frontend (ClusterIP behind ALB) ---
# resource "kubernetes_deployment" "villa_frontend_blue" {
#   metadata { name = "villa-frontend-blue" }
#   spec {
#     replicas = 1
#     selector {
#       match_labels = {
#         app     = "villa-frontend"
#         version = "blue"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           app     = "villa-frontend"
#           version = "blue"
#         }
#       }
#       spec {
#         container {
#           name  = "frontend"
#           image = "nalin745/villa-frontend:v1"
#           port { container_port = 80 }
#         }
#       }
#     }
#   }
#   depends_on = [aws_eks_node_group.villa_workers]
# }

# resource "kubernetes_deployment" "villa_frontend_green" {
#   metadata { name = "villa-frontend-green" }
#   spec {
#     replicas = 2
#     selector {
#       match_labels = {
#         app     = "villa-frontend"
#         version = "green"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           app     = "villa-frontend"
#           version = "green"
#         }
#       }
#       spec {
#         container {
#           name  = "frontend"
#           image = "nalin745/villa-frontend:v2"
#           port { container_port = 80 }
#         }
#       }
#     }
#   }
#   depends_on = [aws_eks_node_group.villa_workers]
# }

# resource "kubernetes_service" "villa_frontend_service" {
#   metadata { name = "villa-frontend-service" }
#   spec {
#     selector = {
#       app     = "villa-frontend"
#       version = var.active_frontend_version
#     }
#     port {
#       port        = 80
#       target_port = 80
#     }
#     type = "ClusterIP"
#   }
# }

# # --- 7. Application Load Balancer (ALB) Ingress ---
# resource "kubernetes_ingress_v1" "villa_alb" {
#   wait_for_load_balancer = true

#   metadata {
#     name = "villa-agency-alb"
#     annotations = {
#       "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
#       "alb.ingress.kubernetes.io/target-type"      = "ip"
#       "alb.ingress.kubernetes.io/healthcheck-path" = "/"
#       "alb.ingress.kubernetes.io/success-codes"    = "200,301,302"
#     }
#   }

#   spec {
#     ingress_class_name = "alb"

#     rule {
#       http {
#         path {
#           path      = "/track"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = kubernetes_service.analytics_service.metadata[0].name
#               port { number = 8004 }
#             }
#           }
#         }

#         path {
#           path      = "/docs"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = kubernetes_service.analytics_service.metadata[0].name
#               port { number = 8004 }
#             }
#           }
#         }

#         path {
#           path      = "/openapi.json"
#           path_type = "Exact"
#           backend {
#             service {
#               name = kubernetes_service.analytics_service.metadata[0].name
#               port { number = 8004 }
#             }
#           }
#         }

#         path {
#           path      = "/metabase"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = kubernetes_service.metabase_service.metadata[0].name
#               port { number = 3000 }
#             }
#           }
#         }

#         path {
#           path      = "/"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = kubernetes_service.villa_frontend_service.metadata[0].name
#               port { number = 80 }
#             }
#           }
#         }
#       }
#     }
#   }

#   depends_on = [helm_release.aws_load_balancer_controller]
# }