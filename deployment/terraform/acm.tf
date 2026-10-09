# ============================================================
# AWS CERTIFICATE MANAGER (ACM)
# Requirements:
# - CloudFront certificates MUST be created in us-east-1
# - ALB certificates created in the ALB region (us-east-1)
# - Enabled conditionally when var.domain_name is provided
# ============================================================

# ACM Certificate for CloudFront (Frontend: app.domain)
resource "aws_acm_certificate" "cf_cert" {
  count             = var.domain_name != "" ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = "${var.app_subdomain}.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "bm_cloudfront_cert"
  }
}

# DNS Validation records for CloudFront certificate
resource "aws_route53_record" "cf_cert_validation" {
  for_each = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.cf_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main[0].zone_id
}

# CloudFront certificate validation waiter
resource "aws_acm_certificate_validation" "cf_cert" {
  count                   = var.domain_name != "" ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cf_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cf_cert_validation : record.fqdn]
}

# ACM Certificate for ALB (API: api.domain)
resource "aws_acm_certificate" "alb_cert" {
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = "${var.api_subdomain}.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "bm_alb_cert"
  }
}

# DNS Validation records for ALB certificate
resource "aws_route53_record" "alb_cert_validation" {
  for_each = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.alb_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main[0].zone_id
}

# ALB certificate validation waiter
resource "aws_acm_certificate_validation" "alb_cert" {
  count                   = var.domain_name != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.alb_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.alb_cert_validation : record.fqdn]
}
