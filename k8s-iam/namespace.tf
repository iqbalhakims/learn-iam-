resource "kubernetes_namespace" "ml_research" {
  metadata {
    name = var.namespace
    labels = {
      "team"    = "ml-research"
      "purpose" = "ml-research-workloads"
    }
  }
}

resource "kubernetes_resource_quota" "ml_research" {
  metadata {
    name      = "ml-research-quota"
    namespace = kubernetes_namespace.ml_research.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"            = var.resource_quota.requests_cpu
      "requests.memory"         = var.resource_quota.requests_memory
      "limits.cpu"              = var.resource_quota.limits_cpu
      "limits.memory"           = var.resource_quota.limits_memory
      "requests.nvidia.com/gpu" = var.resource_quota.requests_gpu
      "pods"                    = var.resource_quota.max_pods
      "persistentvolumeclaims"  = var.resource_quota.max_pvcs
    }
  }
}

resource "kubernetes_limit_range" "ml_research" {
  metadata {
    name      = "ml-research-default-limits"
    namespace = kubernetes_namespace.ml_research.metadata[0].name
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = var.default_container_limits.default_cpu_limit
        memory = var.default_container_limits.default_memory_limit
      }
      default_request = {
        cpu    = var.default_container_limits.default_cpu_request
        memory = var.default_container_limits.default_memory_request
      }
    }
  }
}
