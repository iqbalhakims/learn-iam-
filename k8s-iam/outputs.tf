output "namespace" {
  description = "Namespace the ML research team operates in."
  value       = kubernetes_namespace.ml_research.metadata[0].name
}

output "lead_kubernetes_group" {
  value = "ml-research-leads"
}

output "member_kubernetes_group" {
  value = "ml-research-members"
}

output "eks_describe_cluster_policy_arn" {
  description = "Attach this IAM policy to each principal in lead_principal_arns / member_principal_arns (or their SSO permission set) so they can run `aws eks update-kubeconfig`."
  value       = aws_iam_policy.eks_describe_cluster.arn
}

output "pod_service_account" {
  description = "ServiceAccount to reference (spec.serviceAccountName) in training/inference pod specs to get IRSA access to the configured S3/ECR resources."
  value       = kubernetes_service_account.ml_research_sa.metadata[0].name
}

output "pod_iam_role_arn" {
  value = aws_iam_role.ml_research_pod_role.arn
}

output "kubeconfig_command" {
  description = "Command each team member runs locally once their principal has the describe-cluster policy attached."
  value       = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.aws_region}"
}
