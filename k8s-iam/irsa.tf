# IAM Roles for Service Accounts: workloads in ml-research assume this role
# to reach S3 (datasets/model artifacts) and ECR directly, via a projected
# OIDC token -- no long-lived AWS keys stored as Kubernetes secrets, and
# nothing for a researcher to leak by `kubectl get secret -o yaml`.

locals {
  oidc_provider   = replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")
  service_account = "ml-research-sa"
}

data "aws_iam_policy_document" "irsa_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${local.service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ml_research_pod_role" {
  name               = "ml-research-pod-role-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json
}

data "aws_iam_policy_document" "irsa_permissions" {
  statement {
    sid    = "DatasetAndArtifactAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = concat(
      var.ml_data_bucket_arns,
      [for arn in var.ml_data_bucket_arns : "${arn}/*"],
    )
  }

  dynamic "statement" {
    for_each = length(var.ecr_repository_arns) > 0 ? [1] : []
    content {
      sid       = "PullPushTrainingImages"
      effect    = "Allow"
      actions   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer", "ecr:BatchCheckLayerAvailability", "ecr:PutImage", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload"]
      resources = var.ecr_repository_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.ecr_repository_arns) > 0 ? [1] : []
    content {
      sid       = "EcrAuth"
      effect    = "Allow"
      actions   = ["ecr:GetAuthorizationToken"]
      resources = ["*"] # required by the ECR API; this action has no resource-level permissions
    }
  }
}

resource "aws_iam_policy" "ml_research_pod_policy" {
  name   = "ml-research-pod-policy-${var.cluster_name}"
  policy = data.aws_iam_policy_document.irsa_permissions.json
}

resource "aws_iam_role_policy_attachment" "ml_research_pod_policy" {
  role       = aws_iam_role.ml_research_pod_role.name
  policy_arn = aws_iam_policy.ml_research_pod_policy.arn
}

resource "kubernetes_service_account" "ml_research_sa" {
  metadata {
    name      = local.service_account
    namespace = kubernetes_namespace.ml_research.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ml_research_pod_role.arn
    }
  }
}
