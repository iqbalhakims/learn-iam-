# Project Memory
Last updated: 2026-08-30T15:38:08.016Z
Mode: local (no API key — paste this at the start of a new session)

## Files Touched This Session
- /Users/iqbalfauzi/work/test-iam/claude-memory/SUMMARY.md
- /Users/iqbalfauzi/work/test-iam/claude-memory/DECISIONS.md
- /Users/iqbalfauzi/work/test-iam/claude-memory/MEMORY.md
- /Users/iqbalfauzi/work/test-iam/claude-memory/BUG_FIXES.md
- /Users/iqbalfauzi/work/test-iam/k8s-iam/versions.tf
- /Users/iqbalfauzi/work/test-iam/k8s-iam/providers.tf
- /Users/iqbalfauzi/work/test-iam/k8s-iam/variables.tf
- /Users/iqbalfauzi/work/test-iam/k8s-iam/data.tf
- /Users/iqbalfauzi/work/test-iam/k8s-iam/eks-access-entries.tf
- /Users/iqbalfauzi/work/test-iam/k8s-iam/namespace.tf
- /Users/iqbalfauzi/work/test-iam/k8s-iam/rbac.tf
- /Users/iqbalfauzi/work/test-iam/k8s-iam/irsa.tf
- /Users/iqbalfauzi/work/test-iam/k8s-iam/outputs.tf
- /Users/iqbalfauzi/work/test-iam/k8s-iam/terraform.tfvars.example
- /Users/iqbalfauzi/work/test-iam/k8s-iam/README.md

## Commands Run
- `ls -la /Users/iqbalfauzi/work/test-iam && find /Users/iqbalfauzi/work/test-iam -maxdepth 3 -type f | head -100`
- `mkdir -p /Users/iqbalfauzi/work/test-iam/k8s-iam`
- `cd /Users/iqbalfauzi/work/test-iam/k8s-iam && terraform fmt -check -diff 2>&1; echo "---"; which terraform && terraform `
- `terraform init -backend=false -input=false 2>&1 | tail -30`
- `pwd`
- `sleep 1`
- `cd /Users/iqbalfauzi/work/test-iam/k8s-iam && terraform validate`

## Recent Conversation
…(earlier turns omitted)

s-auth` ConfigMap) to native Kubernetes RBAC — so the actual permissions live in one reviewable place ([rbac.tf](k8s-iam/rbac.tf)), not scattered across AWS-managed policies.

- **Lead** (1 person): full CRUD on workloads + secrets, can delegate namespace access via Role/RoleBinding management — but structurally can't reach cluster-admin (K8s RBAC blocks privilege escalation).
- **Researchers** (4 people): full CRUD on workloads, **read-only** on secrets.
- **AWS access for pods** (S3 datasets/artifacts, ECR) goes through **IRSA** ([irsa.tf](k8s-iam/irsa.tf)) instead of static credentials in Secrets — removes the "leaked AWS key in a K8s secret" risk entirely.
- **Guardrails**: namespace `ResourceQuota` (GPU-aware) + `LimitRange` so one job can't starve the team's shared capacity.

Full rationale is in [README.md](k8s-iam/README.md). I'll confirm `terraform validate` passes once the provider download completes.

USER: <task-notification>
<task-id>b2b5aoqys</task-id>
<tool-use-id>toolu_0173gRJBRcfm5dNA7r4bgzQG</tool-use-id>
<output-file>/private/tmp/claude-501/-Users-iqbalfauzi-work-test-iam/fcfa2aaf-f9df-406e-9257-6da299210bb9/tasks/b2b5aoqys.output</output-file>
<status>completed</status>
<summary>Background command "Initialize terraform without backend to validate providers" completed (exit code 0)</summary>
</task-notification>

ASSISTANT: `terraform validate` passes cleanly.

## Summary

Wrote a complete Terraform stack in [k8s-iam/](k8s-iam/) designing EKS IAM access for the 5-person ML research team:

- **[eks-access-entries.tf](k8s-iam/eks-access-entries.tf)** — maps each person's IAM principal ARN to a Kubernetes group (`ml-research-leads` / `ml-research-members`) via EKS Access Entries (modern replacement for `aws-auth`)
- **[rbac.tf](k8s-iam/rbac.tf)** — the actual permissions: leads get full CRUD + secrets + can delegate access; researchers get full CRUD on workloads but read-only secrets; both get narrow read-only cluster-scoped visibility (nodes/GPU capacity)
- **[namespace.tf](k8s-iam/namespace.tf)** — shared `ml-research` namespace with a GPU-aware `ResourceQuota` and default `LimitRange`
- **[irsa.tf](k8s-iam/irsa.tf)** — pods get S3/ECR access via IRSA instead of static credentials in Secrets
- **[README.md](k8s-iam/README.md)** — design rationale, access matrix, onboarding/offboarding steps
- **[terraform.tfvars.example](k8s-iam/terraform.tfvars.example)** — copy to `terraform.tfvars` and fill in real ARNs/bucket names to use

`terraform validate` passes. Next step when you're ready to apply: fill in `terraform.tfvars` with real principal ARNs and bucket/ECR ARNs, confirm the target cluster's `authentication_mode` is `API` or `API_AND_CONFIG_MAP`, then `terraform plan`.

USER: Check on the background terraform init task (id b2b5aoqys) in /Users/iqbalfauzi/work/test-iam/k8s-iam, then run terraform validate and report/fix any errors in the IAM design Terraform files.

ASSISTANT: That task already completed and I already validated it — `terraform validate` passed with no errors. Nothing further to fix; the [k8s-iam/](k8s-iam/) stack is syntactically valid and ready for you to fill in `terraform.tfvars` and run `terraform plan`.