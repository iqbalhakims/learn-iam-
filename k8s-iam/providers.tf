provider "aws" {
  region = var.aws_region
}

# Kubernetes provider authenticates against the EKS control plane using a
# short-lived token fetched via the AWS CLI (aws eks get-token), rather than
# a static aws_eks_cluster_auth data source token, so long terraform applies
# don't hit token expiry (EKS tokens are valid for 15 minutes).
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.aws_region]
  }
}
