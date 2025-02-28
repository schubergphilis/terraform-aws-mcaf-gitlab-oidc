variable "create_provider" {
  type        = bool
  default     = true
  description = "Toggle to whether or not create the provider. Put to false to not create the provider but instead data source it and create roles only."
}

variable "custom_provider" {
  type = object({
    enabled     = optional(bool, false)
    name        = string
    url         = string
    fingerprint = string
    client_ids  = list(string)
  })
  default     = null
  description = "Create a custom provider."

  validation {
    condition = (
      (var.github_provider != null && var.github_provider.enabled ? 1 : 0) +
      (var.gitlab_provider != null && var.gitlab_provider.enabled ? 1 : 0) +
      (var.custom_provider != null && var.custom_provider.enabled ? 1 : 0)
    ) == 1
    error_message = "Exactly one provider must be enabled. Please enable only one of github_provider, gitlab_provider, or custom_provider."
  }
}

variable "github_provider" {
  type = object({
    enabled     = optional(bool, false)
    name        = optional(string, "GitHub")
    url         = optional(string, "https://token.actions.githubusercontent.com")
    fingerprint = optional(string, "https://token.actions.githubusercontent.com/.well-known/openid-configuration")
    client_ids  = list(string, ["sts.amazonaws.com"])
  })
  default     = null
  description = "Create a github provider."
}

variable "gitlab_provider" {
  type = object({
    enabled     = optional(bool, false)
    name        = optional(string, "GitLab")
    url         = optional(string, "https://gitlab.com")
    fingerprint = optional(string, "https://gitlab.com")
    client_ids  = list(string, ["https://gitlab.com"])
  })
  default     = null
  description = "Create a github provider."
}

variable "iam_roles" {
  type = map(object({
    description              = optional(string, "Role assumed by the IAM OIDC provider")
    name                     = optional(string, null)
    path                     = optional(string, "/")
    permissions_boundary_arn = optional(string, "")
    policy                   = optional(string, null)
    policy_arns              = optional(set(string), [])

    subject_filter_allowed_custom = optional(string)

    subject_filter_allowed_gitlab = optional(object({
      project_path = string
      ref_type     = string
      ref          = string
    }))

    subject_filter_allowed_github = optional(object({
      repository  = string
      branch      = optional(string)
      environment = optional(string)
      tag         = optional(string)
    }))
  }))

  default     = {}
  description = "Configuration for IAM roles, the key of the map is used as the IAM role name. Unless overwritten by setting the name field."

  validation {
    condition = alltrue([
      for role in values(var.iam_roles) : (
        length(compact([
          role.subject_filter_allowed_custom,
          role.subject_filter_allowed_gitlab,
          role.subject_filter_allowed_github
        ])) == 1
      )
    ])
    error_message = "Each IAM role must have exactly one subject filter defined (choose one of subject_filter_allowed_custom, subject_filter_allowed_gitlab, or subject_filter_allowed_github)."
  }

  validation {
    condition = alltrue([
      for role in values(var.iam_roles) : (
        role.subject_filter_allowed_gitlab == null ||
        can(regex("^(\\*|branch|tag)$", role.subject_filter_allowed_gitlab.ref_type))
      )
    ])
    error_message = "If subject_filter_allowed_gitlab is define, ref_type must be '*', 'branch', or 'tag'."
  }

  validation {
    condition = alltrue([
      for role in values(var.iam_roles) : (
        role.subject_filter_allowed_github == null ||
        length(compact([
          role.subject_filter_allowed_github.branch != null ? role.subject_filter_allowed_github.branch : null,
          role.subject_filter_allowed_github.environment != null ? role.subject_filter_allowed_github.environment : null,
          role.subject_filter_allowed_github.tag != null ? role.subject_filter_allowed_github.tag : null
        ])) == 1
      )
    ])
    error_message = "If subject_filter_allowed_github is defined, exactly one of branch, environment, or tag must be specified."
  }

  validation {
    condition = alltrue([
      for role in values(var.iam_roles) : (
        role.subject_filter_allowed_github == null ||
        length(regexall("^[A-Za-z0-9_.-]+?/([A-Za-z0-9_.:/\\-\\*]+)$", role.subject_filter_allowed_github.repository)) > 0
      )
    ])
    error_message = "If subject_filter_allowed_github is defined, the repository must be in the organization/repository format."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "A mapping of tags to assign to all resources."
}
