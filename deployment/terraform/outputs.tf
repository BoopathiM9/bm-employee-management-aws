# ============================================================
# TERRAFORM OUTPUTS
# Provides critical deployment endpoints and resource identifiers
# ============================================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.bm_vpc.id
}

output "alb_dns_name" {
  description = "Application Load Balancer public DNS name"
  value       = aws_lb.bm_alb.dns_name
}

output "alb_http_url" {
  description = "Direct HTTP endpoint for testing ALB to backend"
  value       = "http://${aws_lb.bm_alb.dns_name}"
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (HTTPS default entry point)"
  value       = aws_cloudfront_distribution.bm_cloudfront_dist.domain_name
}

output "cloudfront_https_url" {
  description = "Production HTTPS entry point for the frontend and API"
  value       = "https://${aws_cloudfront_distribution.bm_cloudfront_dist.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (used for CI/CD cache invalidation)"
  value       = aws_cloudfront_distribution.bm_cloudfront_dist.id
}

output "s3_frontend_bucket" {
  description = "Private S3 bucket name holding the React frontend build"
  value       = aws_s3_bucket.bm_frontend_bucket.id
}

output "secrets_manager_secret_name" {
  description = "AWS Secrets Manager secret name storing DB credentials"
  value       = aws_secretsmanager_secret.bm_db_credentials.name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL private endpoint (address:port)"
  value       = aws_db_instance.bm_postgres_db.endpoint
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.bm_backend_asg.name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for production alerts"
  value       = aws_sns_topic.bm_production_alerts.arn
}

output "app_url" {
  description = "Custom domain URL for frontend (if domain configured)"
  value       = var.domain_name != "" ? "https://${var.app_subdomain}.${var.domain_name}" : "https://${aws_cloudfront_distribution.bm_cloudfront_dist.domain_name}"
}

output "api_url" {
  description = "Custom domain URL for API (if domain configured)"
  value       = var.domain_name != "" ? "https://${var.api_subdomain}.${var.domain_name}" : "https://${aws_cloudfront_distribution.bm_cloudfront_dist.domain_name}/api/employees"
}
