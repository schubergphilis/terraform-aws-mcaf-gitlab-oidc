provider "aws" {
  region = "eu-west-1"
}

module "example" {
  source = "../.."

  iam_roles = {
    "example-role" = {
      policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]

      subject_filter_allowed = {
        path     = "mygroup/*"
        ref_type = "branch"
        ref      = "main"
      }
    }
  }
}
