provider "aws" {
  region = "us-west-1"
  dynamic "assume_role" {
    for_each = var.role_arn != null ? [1] : []
    content {
      role_arn = var.role_arn
    }
  }
  default_tags {
    tags = {
      "created_by" : "infrahouse/terraform-aws-debian-repo" # GitHub repository that created a resource
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "aws-us-east-1"
  assume_role {
    role_arn = var.role_arn
  }
  default_tags {
    tags = {
      "created_by" : "infrahouse/terraform-aws-debian-repo" # GitHub repository that created a resource
    }
  }
}
