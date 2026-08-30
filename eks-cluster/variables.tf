variable "aws_region" {
  description = "AWS region to create the VPC and EKS cluster in."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster. Pass this same value as cluster_name to the sibling k8s-iam/ stack."
  type        = string
  default     = "ml-platform-eks"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "node_instance_types" {
  description = "Instance types for the general-purpose managed node group. Small on-demand instances -- sized for testing/RBAC validation, not GPU training."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_group_min_size" {
  type    = number
  default = 2
}

variable "node_group_max_size" {
  type    = number
  default = 4
}

variable "node_group_desired_size" {
  type    = number
  default = 2
}
