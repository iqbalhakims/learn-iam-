# EKS Cluster — ML Research Team

Provisions the cluster that `../k8s-iam/` grants access to. Kept as a
separate stack because cluster lifecycle (who can delete/resize it) and
access-tier lifecycle (who's on the team this month) change on different
schedules and, in a real org, are usually owned by different people
(platform team vs. team lead).

## What this creates

- A new VPC (`vpc.tf`) — 3 AZs, public + private subnets, a single NAT
  gateway (cost-optimized for a test/learning cluster, not multi-AZ HA).
- An EKS cluster (`eks.tf`) using `authentication_mode = "API"` — no
  `aws-auth` ConfigMap, so it plugs directly into `../k8s-iam/`'s
  `aws_eks_access_entry` resources.
- `enable_irsa = true` — required by `../k8s-iam/irsa.tf`'s pod-level S3/ECR
  access.
- One small on-demand managed node group (`t3.large` x2-4) — enough to
  exercise RBAC and run lightweight jobs. Swap in GPU instance types
  (e.g. `g4dn.xlarge`) via `node_instance_types` once you're doing real
  training, not just validating access.

## Usage

```
cp terraform.tfvars.example terraform.tfvars   # edit cluster_name/region as needed
terraform init
terraform apply
```

Then apply `../k8s-iam/` with the same `cluster_name` / `aws_region` to
grant the team access.

## Cost note

This is a real, billed AWS cluster: EKS control plane (~$0.10/hr), 2
t3.large on-demand nodes, and one NAT gateway. Destroy it
(`terraform destroy`) when not in active use if this is purely for
learning/testing.
