locals {
  provider             = var.create_provider == true ? { instance = true } : {}
  data_source_provider = var.create_provider == false ? { instance = true } : {}

  provider_arn = var.create_provider ? aws_iam_openid_connect_provider.gitlab["instance"].arn : data.aws_iam_openid_connect_provider.gitlab["instance"].arn
  provider_url = var.create_provider ? aws_iam_openid_connect_provider.gitlab["instance"].url : data.aws_iam_openid_connect_provider.gitlab["instance"].url
}

# We avoid using https scheme because the Hashicorp TLS provider has started following redirects starting v4.
# See https://github.com/hashicorp/terraform-provider-tls/issues/249
data "tls_certificate" "gitlab" {
  url = "${replace(var.gitlab_url, "https", "tls")}:443"
}

data "aws_iam_openid_connect_provider" "gitlab" {
  for_each = local.data_source_provider

  url = var.gitlab_url
}

resource "aws_iam_openid_connect_provider" "gitlab" {
  for_each = local.provider

  url             = var.gitlab_url
  client_id_list  = [var.gitlab_url]
  thumbprint_list = [data.tls_certificate.gitlab.certificates[0].sha1_fingerprint]
  tags            = var.tags
}

data "aws_iam_policy_document" "assume_role_policy" {
  for_each = var.iam_roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }

    # A concatenation of metadata describing the GitLab CI/CD workflow including the group, project, branch, and tag. The sub field is in the following format:
    # project_path:{group}/{project}:ref_type:{type}:ref:{branch_name}
    # https://docs.gitlab.com/ee/ci/cloud_services/index.html#configure-a-conditional-role-with-oidc-claims
    condition {
      test     = "StringLike"
      variable = "${local.provider_url}:sub"
      values   = ["project_path:${each.value.subject_filter_allowed.path}:ref_type:${each.value.subject_filter_allowed.ref_type}:ref:${each.value.subject_filter_allowed.ref}"]
    }
  }
}

module "oidc_role" {
  source  = "schubergphilis/mcaf-role/aws"
  version = "~> 0.4.0"

  for_each = var.iam_roles

  name                 = each.value.name != null ? each.value.name : each.key
  assume_policy        = data.aws_iam_policy_document.assume_role_policy[each.key].json
  description          = each.value.description
  path                 = each.value.path
  permissions_boundary = each.value.permissions_boundary_arn
  policy_arns          = each.value.policy_arns
  postfix              = false
  role_policy          = each.value.policy
  tags                 = var.tags
}
