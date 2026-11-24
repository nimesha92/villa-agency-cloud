output "eks_cluster_name" {
  description = "Provisioned EKS Cluster Name"
  value       = aws_eks_cluster.villa.name
}

output "eks_cluster_endpoint" {
  description = "EKS Control Plane API Endpoint"
  value       = aws_eks_cluster.villa.endpoint
}

output "configure_kubectl" {
  description = "Run this command to connect kubectl to your cluster"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.villa.name}"
}