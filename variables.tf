variable "create_provider" {
  type        = bool
  default     = true
  description = "Toggle to whether or not create the provider. Put to false to not create the provider but instead data source it and create roles only."
}

variable "gitlab_url" {
  type        = string
  default     = "https://gitlab.com"
  description = "GitLab URL. The address of your GitLab instance, such as https://gitlab.com or https://gitlab.example.com."

  validation {
    condition     = can(regex("^https", var.gitlab_url))
    error_message = "URL should start with 'https'."
  }
}

variable "iam_roles" {
  type = map(object({
    description              = optional(string, "Role assumed by the Gitlab IAM OIDC provider")
    name                     = optional(string, null)
    path                     = optional(string, "/")
    permissions_boundary_arn = optional(string, "")
    policy                   = optional(string, null)
    policy_arns              = optional(set(string), [])

    subject_filter_allowed = object({
      path     = string
      ref_type = string
      ref      = string
    })
  }))
  description = "Configuration for IAM roles, the key of the map is used as the IAM role name. Unless overwritten by setting the name field."

  validation {
    condition     = alltrue([for o in var.iam_roles : can(regex("^(\\*|branch|tag)$", o.subject_filter_allowed.ref_type))])
    error_message = "ref_type must be '*', 'branch', or 'tag'."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "A mapping of tags to assign to all resources."
}
