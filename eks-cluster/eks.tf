module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # API-only auth: no aws-auth ConfigMap. Grants match exactly what the
  # sibling k8s-iam/ stack creates via aws_eks_access_entry -- see that
  # stack's eks-access-entries.tf for the lead/mlops/member tiers.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  # Required for the sibling k8s-iam/ stack's IRSA pod role (irsa.tf) to work.
  enable_irsa = true

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    general = {
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size
    }
  }

  tags = {
    Environment = "learning"
    Team        = "ml-research"
  }
}
