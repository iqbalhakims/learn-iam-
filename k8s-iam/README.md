# ML Research Team — EKS IAM Access Design

Access design for a 5-person ML research team (1 lead + 4 researchers) on an
existing AWS EKS cluster.

## Design decisions

**Two tiers, one shared namespace.** All five people work in a single
`ml-research` namespace. Splitting into per-user namespaces was rejected for
a team this size — it multiplies the number of RBAC objects and quotas to
maintain for no real isolation benefit, since the team already trusts each
other's code and shares GPU capacity. Per-project namespaces were also
rejected: ML research projects are short-lived and overlapping, so
namespace-per-project churns faster than it's worth. If the team later
splits into workstreams with different data-sensitivity levels, that's the
trigger to revisit this.

**EKS Access Entries, not the `aws-auth` ConfigMap.** Access entries are the
current AWS-supported mechanism for mapping IAM principals to Kubernetes
identities; they're managed as normal Terraform resources (no more editing a
ConfigMap out-of-band and risking locking yourself out of the cluster). The
cluster's `authentication_mode` must be `API` or `API_AND_CONFIG_MAP` for
this to work — that's a prerequisite of the underlying cluster resource
(managed outside this stack) and is called out again in `data.tf`.

**No AWS-managed access policies.** EKS ships broad `AmazonEKSAdminPolicy` /
`EditPolicy` / `ViewPolicy` associations, but they're coarse (e.g. edit
includes secrets write). Instead, access entries only set a
`kubernetes_groups` membership (`ml-research-leads` / `ml-research-members`),
and the actual permissions live entirely in native Kubernetes RBAC
(`rbac.tf`). One source of truth for "what can this tier actually do,"
reviewable in a normal PR diff.

**Direct principal mapping, no shared assume-role.** `lead_principal_arns`
and `member_principal_arns` take each person's existing IAM identity (an IAM
user, or more realistically an Identity Center / SSO permission-set role)
directly. This avoids adding an extra shared-role indirection layer with its
own trust policy and session-tagging to get right — EKS access entries scale
fine to five (or fifty) individual principals, so the indirection buys
nothing here.

**IRSA instead of static AWS creds in Secrets.** Training/inference pods
that need S3 (datasets, model artifacts) or ECR access use the
`ml-research-sa` ServiceAccount, which is bound via IRSA to a scoped IAM
role (`irsa.tf`). This is why researchers only get **read-only** access to
Kubernetes `Secrets` (tier 2) rather than none at all — they can still read
an image-pull secret if one exists — while AWS access itself never touches
a Secret object at all. Removes an entire class of "researcher `kubectl get
secret -o yaml`'s the team's S3 key" incidents.

**Escalation is structurally blocked, not just policy.** The lead role can
create/modify `Role`/`RoleBinding` objects (to delegate namespace access to
a collaborator) but not `ClusterRole`/`ClusterRoleBinding`, and Kubernetes
RBAC's built-in escalation check means a `Role` can never be used to grant
permissions its holder doesn't already have. There's no path from "namespace
lead" to "cluster-admin" short of a platform-team-approved change to this
Terraform.

## Access matrix

| Capability | `ml-research-leads` | `ml-research-members` |
|---|---|---|
| Pods / Deployments / Jobs / CronJobs / Services / ConfigMaps / PVCs (CRUD) | ✅ | ✅ |
| `pods/exec`, `pods/log`, `pods/portforward` | ✅ | ✅ |
| Secrets | full CRUD | read-only |
| Manage namespace Roles/RoleBindings (delegate access) | ✅ | ❌ |
| ClusterRoles / ClusterRoleBindings / other namespaces | ❌ | ❌ |
| Read-only: nodes, namespaces, storage classes, priority classes (cluster-scoped) | ✅ | ✅ |
| ResourceQuota / LimitRange changes | ❌ (platform team only) | ❌ |
| AWS S3 / ECR (via pod IRSA, not user identity) | via `ml-research-sa` | via `ml-research-sa` |

## Guardrails on the namespace itself

- `ResourceQuota`: caps aggregate CPU/memory/GPU requests and limits, pod
  count, and PVC count for the whole team (`variables.tf:resource_quota`) —
  sized for a 5-person team, tune to actual cluster capacity.
- `LimitRange`: gives every container a default CPU/memory request+limit so
  one job submitted without resource fields can't consume the whole quota.

## Onboarding / offboarding a team member

- **Onboard**: add their principal ARN to `lead_principal_arns` or
  `member_principal_arns` in `terraform.tfvars`, `terraform apply`. Attach
  the output `eks_describe_cluster_policy_arn` to their IAM identity (if not
  already covered by an existing policy/permission set), then they run the
  `kubeconfig_command` output.
- **Offboard**: remove their ARN from the list, `terraform apply`. The
  access entry is deleted immediately; no cluster-side credential rotation
  needed since there's no long-lived shared secret.

## Prerequisites this stack assumes

- The EKS cluster already exists and has `authentication_mode` set to `API`
  or `API_AND_CONFIG_MAP`.
- The cluster's OIDC provider is already registered as an IAM OIDC identity
  provider (standard for any cluster already using IRSA elsewhere).
- Team members' IAM identities already exist (IAM users or SSO permission
  set roles) — this stack grants access to existing identities, it doesn't
  create them.

## Files

| File | Purpose |
|---|---|
| `eks-access-entries.tf` | IAM principal → Kubernetes group mapping (AWS side of the bridge) |
| `rbac.tf` | Kubernetes group → permissions (K8s side of the bridge) |
| `namespace.tf` | Namespace, ResourceQuota, LimitRange |
| `irsa.tf` | Pod-level AWS access (S3/ECR) via IRSA, no static credentials |
| `variables.tf` / `terraform.tfvars.example` | Inputs — copy the example to `terraform.tfvars` and fill in real ARNs |
