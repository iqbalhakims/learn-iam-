# --- Tier 1: ml-research-leads -----------------------------------------
# Namespace-admin for ml-research: full lifecycle control over workloads and
# secrets, plus the ability to delegate namespace access (e.g. to a
# collaborating intern) by managing Roles/RoleBindings. Kubernetes RBAC's
# built-in escalation check prevents this Role from ever granting rights it
# doesn't itself have, so this cannot be used to reach cluster-admin.

resource "kubernetes_role" "ml_research_lead" {
  metadata {
    name      = "ml-research-lead"
    namespace = kubernetes_namespace.ml_research.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "pods/exec", "pods/portforward", "services", "configmaps", "persistentvolumeclaims", "events"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "rolebindings"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "ml_research_lead" {
  metadata {
    name      = "ml-research-lead-binding"
    namespace = kubernetes_namespace.ml_research.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.ml_research_lead.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "ml-research-leads"
    api_group = "rbac.authorization.k8s.io"
  }
}

# --- Tier 2: ml-research-members -----------------------------------------
# Namespace-edit for the researchers: full control over their own workloads
# (training jobs, notebooks-as-pods, services) but read-only on secrets --
# shared credentials for AWS access are handled via IRSA (irsa.tf) instead
# of secrets, so read-only is enough to consume, e.g., an image pull secret.
# No RBAC-management rights: researchers cannot grant themselves or others
# broader access.

resource "kubernetes_role" "ml_research_member" {
  metadata {
    name      = "ml-research-member"
    namespace = kubernetes_namespace.ml_research.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "pods/exec", "pods/portforward", "services", "configmaps", "persistentvolumeclaims", "events"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "ml_research_member" {
  metadata {
    name      = "ml-research-member-binding"
    namespace = kubernetes_namespace.ml_research.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.ml_research_member.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "ml-research-members"
    api_group = "rbac.authorization.k8s.io"
  }
}

# --- Cluster-scoped read-only: node/GPU visibility -----------------------
# Both tiers get narrow, read-only visibility into cluster-scoped objects so
# they can check GPU node capacity and available storage classes before
# scheduling a job. No write access, no other namespaces, no secrets.

resource "kubernetes_cluster_role" "ml_research_cluster_view" {
  metadata {
    name = "ml-research-cluster-view"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "namespaces"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["scheduling.k8s.io"]
    resources  = ["priorityclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "ml_research_cluster_view" {
  metadata {
    name = "ml-research-cluster-view-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.ml_research_cluster_view.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "ml-research-leads"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "Group"
    name      = "ml-research-members"
    api_group = "rbac.authorization.k8s.io"
  }
}
