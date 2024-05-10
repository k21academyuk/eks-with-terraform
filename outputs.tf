# Define outputs to expose important information about the EKS cluster
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"  // Description of the output
  value       = module.eks.cluster_endpoint       // Value retrieved from the EKS module
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"  // Description of the output
  value       = module.eks.cluster_security_group_id  // Value retrieved from the EKS module
}

output "region" {
  description = "AWS region"  // Description of the output
  value       = var.region     // Value retrieved from the input variable
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"  // Description of the output
  value       = module.eks.cluster_name     // Value retrieved from the EKS module
}
