data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

# The cluster's OIDC provider must already be registered as an IAM OIDC
# identity provider (standard EKS setup, usually done alongside the cluster).
data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}
