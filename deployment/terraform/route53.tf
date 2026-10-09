# ============================================================
# ROUTE 53 DNS RECORDS
# Conditional on var.domain_name being set
# ============================================================

# Frontend: app.<domain> → CloudFront Distribution
resource "aws_route53_record" "app" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.bm_cloudfront_dist.domain_name
    zone_id                = aws_cloudfront_distribution.bm_cloudfront_dist.hosted_zone_id
    evaluate_target_health = false
  }
}

# API: api.<domain> → Application Load Balancer
resource "aws_route53_record" "api" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "${var.api_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.bm_alb.dns_name
    zone_id                = aws_lb.bm_alb.zone_id
    evaluate_target_health = true
  }
}
