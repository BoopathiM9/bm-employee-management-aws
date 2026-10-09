# ============================================================
# General
# ============================================================
variable "aws_region" {
  description = "Primary AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "production"
}

variable "project_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
  default     = "bm"
}

# ============================================================
# Networking
# ============================================================
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "private_app_subnet_1_cidr" {
  type    = string
  default = "10.0.11.0/24"
}

variable "private_app_subnet_2_cidr" {
  type    = string
  default = "10.0.12.0/24"
}

variable "private_db_subnet_1_cidr" {
  type    = string
  default = "10.0.21.0/24"
}

variable "private_db_subnet_2_cidr" {
  type    = string
  default = "10.0.22.0/24"
}

variable "az_1" {
  description = "Primary availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "az_2" {
  description = "Secondary availability zone"
  type        = string
  default     = "us-east-1b"
}

# ============================================================
# EC2 / Auto Scaling
# ============================================================
variable "instance_type" {
  description = "EC2 instance type for backend servers"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances in ASG"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances in ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in ASG"
  type        = number
  default     = 4
}

# ============================================================
# RDS PostgreSQL
# ============================================================
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "bm_employees_db"
}

variable "db_username" {
  description = "PostgreSQL master username (non-sensitive, stored in Secrets Manager)"
  type        = string
  default     = "bm_admin"
}

variable "db_backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = true
}

# ============================================================
# Domain / DNS (Optional - leave blank to skip Route53/ACM)
# ============================================================
variable "domain_name" {
  description = "Your registered domain name (e.g. example.com). Leave blank to skip Route53/ACM/CloudFront."
  type        = string
  default     = ""
}

variable "app_subdomain" {
  description = "Subdomain for the React frontend"
  type        = string
  default     = "app"
}

variable "api_subdomain" {
  description = "Subdomain for the backend API"
  type        = string
  default     = "api"
}

# ============================================================
# S3
# ============================================================
variable "frontend_bucket_name" {
  description = "S3 bucket name for React frontend (must be globally unique)"
  type        = string
  default     = "bm-frontend-app-prod"
}

# ============================================================
# Monitoring / Alerts
# ============================================================
variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications via SNS"
  type        = string
  default     = ""
}

# ============================================================
# GitHub OIDC (CI/CD)
# ============================================================
variable "github_repo" {
  description = "GitHub repository in the format owner/repo (e.g. boopathi/employee-management-aws)"
  type        = string
  default     = ""
}
