# We avoid using https scheme because the Hashicorp TLS provider has started following redirects starting v4.
# See https://github.com/hashicorp/terraform-provider-tls/issues/249
data "tls_certificate" "gitlab" {
  url = "${replace(var.gitlab_url, "https", "tls")}:443"
}

resource "aws_iam_openid_connect_provider" "gitlab" {
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
      identifiers = [aws_iam_openid_connect_provider.gitlab.arn]
    }

    # A concatenation of metadata describing the GitLab CI/CD workflow including the group, project, branch, and tag. The sub field is in the following format:
    # project_path:{group}/{project}:ref_type:{type}:ref:{branch_name}  
    # https://docs.gitlab.com/ee/ci/cloud_services/index.html#configure-a-conditional-role-with-oidc-claims  
    condition {
      test     = "StringLike"
      variable = "${aws_iam_openid_connect_provider.gitlab.url}:sub"
      values   = ["project_path:${each.value.subject_filter_allowed.path}:ref_type:${each.value.subject_filter_allowed.ref_type}:ref:${each.value.subject_filter_allowed.ref}"]
    }
  }
}

module "oidc_role" {
  source  = "schubergphilis/mcaf-role/aws"
  version = "~> 0.4.0"

  for_each = var.iam_roles

  name                 = each.key
  assume_policy        = data.aws_iam_policy_document.assume_role_policy[each.key].json
  description          = each.value.description
  path                 = each.value.path
  permissions_boundary = each.value.permissions_boundary_arn
  policy_arns          = each.value.policy_arns
  postfix              = false
  role_policy          = each.value.policy
  tags                 = var.tags
}
