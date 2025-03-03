# terraform-aws-mcaf-gitlab-oidc

Terraform module to configure GitLab as an IAM OIDC identity provider in AWS.

> [!WARNING]
> This module is deprecated.
> A submodule with the same functionality is now available as part of 
> [`terraform-aws-mcaf-oidc`](https://registry.terraform.io/modules/schubergphilis/mcaf-oidc/aws/latest/submodules/gitlab).
> Please refer to the [upgrade guide](https://github.com/schubergphilis/terraform-aws-mcaf-oidc/blob/main/UPGRADING.md) for migration instructions.

IMPORTANT: We do not pin modules to versions in our examples. We highly recommend that in your code you pin the version to the exact version you are using so that your infrastructure remains stable.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_oidc_role"></a> [oidc\_role](#module\_oidc\_role) | schubergphilis/mcaf-role/aws | ~> 0.4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.gitlab](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_openid_connect_provider.gitlab](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [tls_certificate.gitlab](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_provider"></a> [create\_provider](#input\_create\_provider) | Toggle to whether or not create the provider. Put to false to not create the provider but instead data source it and create roles only. | `bool` | `true` | no |
| <a name="input_gitlab_url"></a> [gitlab\_url](#input\_gitlab\_url) | GitLab URL. The address of your GitLab instance, such as https://gitlab.com or https://gitlab.example.com. | `string` | `"https://gitlab.com"` | no |
| <a name="input_iam_roles"></a> [iam\_roles](#input\_iam\_roles) | Configuration for IAM roles, the key of the map is used as the IAM role name. Unless overwritten by setting the name field. | <pre>map(object({<br/>    description              = optional(string, "Role assumed by the Gitlab IAM OIDC provider")<br/>    name                     = optional(string, null)<br/>    path                     = optional(string, "/")<br/>    permissions_boundary_arn = optional(string, "")<br/>    policy                   = optional(string, null)<br/>    policy_arns              = optional(set(string), [])<br/><br/>    subject_filter_allowed = object({<br/>      path     = string<br/>      ref_type = string<br/>      ref      = string<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources. | `map(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_roles"></a> [iam\_roles](#output\_iam\_roles) | Map GitLab OIDC IAM roles name and ARN |
<!-- END_TF_DOCS -->

## Licensing

100% Open Source and licensed under the Apache License Version 2.0. See [LICENSE](https://github.com/schubergphilis/terraform-aws-mcaf-gitlab-oidc/blob/main/LICENSE) for full details.
