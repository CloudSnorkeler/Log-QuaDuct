data "aws_region" "current" {}
provider "null" {}
data "aws_iam_account_alias" "current" {}


locals {
  # Retrieve VPC name from Name tag
  name_fixed_spliced  = split("-", data.aws_iam_account_alias.current.account_alias)
  account_nickname    = element(local.name_fixed_spliced, 1)
  account_environment = element(local.name_fixed_spliced, 3)
  account_region      = data.aws_region.current.name
}

# Corrected output
output "account_nickname" {
  value = local.account_nickname
}

# Corrected output
output "account_environment" {
  value = local.account_environment
}

# Corrected output
output "account_region" {
  value = local.account_region
}
