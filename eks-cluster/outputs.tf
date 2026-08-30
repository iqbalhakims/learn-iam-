output "cluster_name" {
  description = "Pass this as cluster_name to the sibling k8s-iam/ stack."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN -- k8s-iam/data.tf looks this up itself by issuer URL, shown here for reference/debugging."
  value       = module.eks.oidc_provider_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}
