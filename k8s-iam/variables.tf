variable "aws_region" {
  description = "AWS region the EKS cluster runs in."
  type        = string
}

variable "cluster_name" {
  description = "Name of the existing EKS cluster to grant access to. The cluster must have authentication_mode set to API or API_AND_CONFIG_MAP (access entries do not work in CONFIG_MAP-only mode)."
  type        = string
}

variable "namespace" {
  description = "Shared namespace the ML research team operates in."
  type        = string
  default     = "ml-research"
}

variable "lead_principal_arns" {
  description = "IAM principal ARNs (IAM users, or SSO/Identity Center permission-set roles) for the ML research team lead(s). Granted namespace-admin-level RBAC."
  type        = list(string)

  validation {
    condition     = length(var.lead_principal_arns) > 0
    error_message = "At least one lead principal ARN is required."
  }
}

variable "member_principal_arns" {
  description = "IAM principal ARNs (IAM users, or SSO/Identity Center permission-set roles) for the ML researchers. Granted namespace-edit-level RBAC, read-only on secrets."
  type        = list(string)

  validation {
    condition     = length(var.member_principal_arns) > 0
    error_message = "At least one member principal ARN is required."
  }
}

variable "mlops_principal_arns" {
  description = "IAM principal ARNs (IAM users, or SSO/Identity Center permission-set roles) for the MLOps engineers supporting this team. Mapped into the same ml-research-leads Kubernetes group as lead_principal_arns, so they get identical namespace-admin-level RBAC -- no separate Role to keep in sync."
  type        = list(string)
  default     = []
}

variable "ml_data_bucket_arns" {
  description = "S3 bucket ARNs (datasets/model artifacts) the team's workloads need access to. Used to scope the IRSA pod role instead of handing out static credentials via K8s secrets."
  type        = list(string)
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs the team's training/inference images are pulled from or pushed to. Optional; leave empty if the cluster nodes already have image pull access via the node IAM role."
  type        = list(string)
  default     = []
}

variable "resource_quota" {
  description = "Namespace-wide ResourceQuota for the ml-research namespace. Sized for a 5-person research team sharing GPU nodes; tune to your cluster's actual capacity."
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
    requests_gpu    = string
    max_pods        = string
    max_pvcs        = string
  })
  default = {
    requests_cpu    = "40"
    requests_memory = "160Gi"
    limits_cpu      = "80"
    limits_memory   = "320Gi"
    requests_gpu    = "8"
    max_pods        = "100"
    max_pvcs        = "20"
  }
}

variable "default_container_limits" {
  description = "Default per-container CPU/memory request+limit applied via LimitRange when a pod spec omits them, so one un-bounded job can't starve the namespace quota."
  type = object({
    default_cpu_limit      = string
    default_memory_limit   = string
    default_cpu_request    = string
    default_memory_request = string
  })
  default = {
    default_cpu_limit      = "4"
    default_memory_limit   = "16Gi"
    default_cpu_request    = "1"
    default_memory_request = "4Gi"
  }
}
