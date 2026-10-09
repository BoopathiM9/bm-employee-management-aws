# Latest Amazon Linux 2023 AMI for us-east-1
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Current AWS account ID and region (used in IAM policies)
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Route53 hosted zone (only looked up when domain_name is provided)
data "aws_route53_zone" "main" {
  count        = var.domain_name != "" ? 1 : 0
  name         = var.domain_name
  private_zone = false
}
