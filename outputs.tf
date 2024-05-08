output "iam_roles" {
  value = {
    for name, role in module.oidc_role :
    name => role.arn
  }
  description = "Map GitLab OIDC IAM roles name and ARN"
}
