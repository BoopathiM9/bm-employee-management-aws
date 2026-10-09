terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary provider - us-east-1 (all main resources)
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "bm_employee_management"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Secondary provider - us-east-1 explicitly for ACM (CloudFront certificates MUST be in us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "bm_employee_management"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
