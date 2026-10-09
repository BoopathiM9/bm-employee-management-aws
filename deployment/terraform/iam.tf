# ============================================================
# EC2 INSTANCE ROLE (bm_ec2_instance_role)
# Runtime permissions ONLY - least privilege
# ============================================================

# Why EC2 and CI/CD roles are SEPARATE:
# - EC2 role: runtime permissions (read secrets, write logs, SSM access)
# - CI/CD role: deployment permissions (push to S3, update ASG, update secrets)
# - Separation of duties: compromised EC2 ≠ compromised deployment pipeline
# - Reduced blast radius: one role cannot do the other's job
# - Different trust relationships: EC2 trusts ec2.amazonaws.com, CI/CD trusts GitHub OIDC

resource "aws_iam_role" "bm_ec2_instance_role" {
  name        = "bm_ec2_instance_role"
  description = "Runtime IAM role for backend EC2 instances - least privilege"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "bm_ec2_instance_role"
  }
}

# EC2 Policy: Secrets Manager + CloudWatch + SSM only
resource "aws_iam_policy" "bm_ec2_policy" {
  name        = "bm_ec2_policy"
  description = "Least privilege policy for EC2 backend instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Secrets Manager: read ONLY the application database secret
      {
        Sid    = "SecretsManagerReadOnly"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:bm_db_credentials*"
      },
      # S3: read deployment package
      {
        Sid    = "S3DeployPackageRead"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.bm_frontend_bucket.arn}/*"
      },
      # CloudWatch: write logs and metrics
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      # SSM: required for Session Manager (no SSH needed)
      {
        Sid    = "SSMSessionManager"
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bm_ec2_policy_attachment" {
  role       = aws_iam_role.bm_ec2_instance_role.name
  policy_arn = aws_iam_policy.bm_ec2_policy.arn
}

# EC2 Instance Profile (what gets attached to the EC2 instance)
resource "aws_iam_instance_profile" "bm_ec2_instance_profile" {
  name = "bm_ec2_instance_profile"
  role = aws_iam_role.bm_ec2_instance_role.name

  tags = {
    Name = "bm_ec2_instance_profile"
  }
}

# ============================================================
# GITHUB ACTIONS CICD ROLE (bm_cicd_deploy_role)
# Uses OIDC - no long-lived AWS keys in GitHub!
# Trust policy: only allows tokens from your specific GitHub repo
# ============================================================
resource "aws_iam_openid_connect_provider" "github_oidc" {
  count = var.github_repo != "" ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint (stable value)
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "bm_github_oidc_provider"
  }
}

resource "aws_iam_role" "bm_cicd_deploy_role" {
  count       = var.github_repo != "" ? 1 : 0
  name        = "bm_cicd_deploy_role"
  description = "GitHub Actions deployment role - uses OIDC, no static keys"

  # Trust policy: only your specific GitHub repo can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_oidc[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Only allow your specific repo - not any GitHub repo
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "bm_cicd_deploy_role"
  }
}

resource "aws_iam_policy" "bm_cicd_deploy_policy" {
  count       = var.github_repo != "" ? 1 : 0
  name        = "bm_cicd_deploy_policy"
  description = "Deployment permissions for GitHub Actions CI/CD pipeline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3: deploy frontend build artifacts
      {
        Sid    = "S3FrontendDeploy"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.frontend_bucket_name}",
          "arn:aws:s3:::${var.frontend_bucket_name}/*"
        ]
      },
      # CloudFront: invalidate cache after frontend deploy
      {
        Sid    = "CloudFrontInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = "*"
      },
      # SSM: send commands to EC2 for backend deployment
      {
        Sid    = "SSMSendCommand"
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:DescribeInstanceInformation"
        ]
        Resource = "*"
      },
      # EC2 + ASG: describe instances for health checks
      {
        Sid    = "DescribeResources"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "elasticloadbalancing:DescribeTargetHealth"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bm_cicd_policy_attachment" {
  count      = var.github_repo != "" ? 1 : 0
  role       = aws_iam_role.bm_cicd_deploy_role[0].name
  policy_arn = aws_iam_policy.bm_cicd_deploy_policy[0].arn
}
