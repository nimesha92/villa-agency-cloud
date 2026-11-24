terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.2.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_eks_cluster_auth" "villa" {
  name       = aws_eks_cluster.villa.name
  depends_on = [aws_eks_cluster.villa]
}

provider "kubernetes" {
  host                   = aws_eks_cluster.villa.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.villa.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.villa.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.villa.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.villa.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.villa.token
  }
}
