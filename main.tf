provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  account_suffix = substr(data.aws_caller_identity.current.account_id, -6, -1)
  name_prefix    = "fp-lab"

  common_tags = {
    Project   = "fp-lab"
    ManagedBy = "terraform"
  }
}
