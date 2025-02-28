locals {
  provider = coalesce(var.github_provider, var.gitlab_provider, var.custom_provider)

  provider_arn = var.create_provider ? aws_iam_openid_connect_provider.default["instance"].arn : data.aws_iam_openid_connect_provider.default["instance"].arn
  provider_url = var.create_provider ? aws_iam_openid_connect_provider.default["instance"].url : data.aws_iam_openid_connect_provider.default["instance"].url
}


################################################################################
# OIDC Provider
################################################################################

# We avoid using https scheme because the Hashicorp TLS provider has started following redirects starting v4.
# See https://github.com/hashicorp/terraform-provider-tls/issues/249
data "tls_certificate" "fingerprint" {
  url = "${replace(local.provider.url, "https", "tls")}:443"
}

data "aws_iam_openid_connect_provider" "default" {
  for_each = !var.create_provider ? { instance = true } : {}

  url = local.provider.url
}

resource "aws_iam_openid_connect_provider" "default" {
  for_each = var.create_provider ? { instance = true } : {}

  url             = local.provider.url
  client_id_list  = local.provider.client_ids
  thumbprint_list = [data.tls_certificate.fingerprint.certificates[0].sha1_fingerprint]
  tags            = var.tags
}

################################################################################
# AWS IAM Role
################################################################################


data "aws_iam_policy_document" "assume_role_policy" {
  for_each = var.iam_roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }

    # GitLab
    # A concatenation of metadata describing the GitLab CI/CD workflow including the group, project, branch, and tag. The sub field is in the following format:
    # project_path:{group}/{project}:ref_type:{type}:ref:{branch_name}
    # https://docs.gitlab.com/ee/ci/cloud_services/index.html#configure-a-conditional-role-with-oidc-claims

    # GitHub
    # todo
    # https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
    condition {
      test     = "StringLike"
      variable = "${local.provider_url}:sub"
      values = compact([
        each.value.subject_filter_allowed_gitlab != null ? "project_path:${each.value.subject_filter_allowed_gitlab.project_path}:ref_type:${each.value.subject_filter_allowed_gitlab.ref_type}:ref:${each.value.subject_filter_allowed_gitlab.ref}" : null,
        each.value.subject_filter_allowed_github != null ? "repo:${each.value.subject_filter_allowed_github.repository}:ref:refs/heads/${each.value.subject_filter_allowed_github.branch}" : null,
        each.value.subject_filter_allowed_github != null && each.value.subject_filter_allowed_github.environment != null ? "repo:${each.value.subject_filter_allowed_github.repository}:env:${each.value.subject_filter_allowed_github.environment}" : null,
        each.value.subject_filter_allowed_github != null && each.value.subject_filter_allowed_github.tag != null ? "repo:${each.value.subject_filter_allowed_github.repository}:ref:refs/tags/${each.value.subject_filter_allowed_github.tag}" : null,
        each.value.subject_filter_allowed_custom
      ])
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
