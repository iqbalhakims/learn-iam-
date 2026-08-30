# Maps IAM principals directly to Kubernetes RBAC groups using EKS Access
# Entries (the current AWS-recommended mechanism — replaces the aws-auth
# ConfigMap). No AWS-managed access policies are associated here: authorization
# is deliberately left entirely to the namespace-scoped RBAC Roles in rbac.tf,
# so the two tiers of access are defined in exactly one place.

resource "aws_eks_access_entry" "lead" {
  for_each = toset(var.lead_principal_arns)

  cluster_name      = var.cluster_name
  principal_arn     = each.value
  kubernetes_groups = ["ml-research-leads"]
  type              = "STANDARD"
}

resource "aws_eks_access_entry" "mlops" {
  for_each = toset(var.mlops_principal_arns)

  cluster_name      = var.cluster_name
  principal_arn     = each.value
  kubernetes_groups = ["ml-research-leads"]
  type              = "STANDARD"
}

resource "aws_eks_access_entry" "member" {
  for_each = toset(var.member_principal_arns)

  cluster_name      = var.cluster_name
  principal_arn     = each.value
  kubernetes_groups = ["ml-research-members"]
  type              = "STANDARD"
}

# IAM permissions needed client-side to discover the cluster and build a
# kubeconfig (`aws eks update-kubeconfig`). This does NOT grant any
# Kubernetes-level access on its own -- that comes from the access entries
# above plus the RBAC Roles in rbac.tf.
resource "aws_iam_policy" "eks_describe_cluster" {
  name        = "ml-research-eks-describe-${var.cluster_name}"
  description = "Allows the ML research team to discover the EKS cluster to build a kubeconfig."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DescribeClusterForKubeconfig"
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = data.aws_eks_cluster.this.arn
      }
    ]
  })
}
