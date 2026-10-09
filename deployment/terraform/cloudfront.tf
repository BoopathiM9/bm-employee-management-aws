# ============================================================
# CLOUDFRONT ORIGIN ACCESS CONTROL (bm_s3_oac)
# Secures S3 bucket access so ONLY CloudFront can read files
# ============================================================
resource "aws_cloudfront_origin_access_control" "bm_s3_oac" {
  name                              = "bm-s3-oac"
  description                       = "Origin Access Control for BM Employee Frontend S3 Bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Managed Cache Policies
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
}

# ============================================================
# CLOUDFRONT DISTRIBUTION (bm_cloudfront_dist)
# Routes:
# - Default (*)  → S3 Frontend Bucket (via OAC)
# - /api/*       → ALB (Application Load Balancer)
# - /health      → ALB
# ============================================================
resource "aws_cloudfront_distribution" "bm_cloudfront_dist" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "BM Enterprise Employee Management Portal CDN"
  default_root_object = "index.html"

  aliases = var.domain_name != "" ? ["${var.app_subdomain}.${var.domain_name}"] : []

  # Origin 1: S3 Bucket (React Frontend)
  origin {
    domain_name              = aws_s3_bucket.bm_frontend_bucket.bucket_regional_domain_name
    origin_id                = "S3-BM-Frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.bm_s3_oac.id
  }

  # Origin 2: ALB (Backend Node.js API)
  origin {
    domain_name = aws_lb.bm_alb.dns_name
    origin_id   = "ALB-BM-Backend"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
    }
  }

  # Default Cache Behavior (React SPA from S3)
  default_cache_behavior {
    target_origin_id       = "S3-BM-Frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  # Ordered Cache Behavior: /api/* → Forwarded directly to ALB
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "ALB-BM-Backend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
  }

  # Ordered Cache Behavior: /health → Forwarded to ALB
  ordered_cache_behavior {
    path_pattern           = "/health"
    target_origin_id       = "ALB-BM-Backend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
  }

  # SPA Routing Fallback (Returns index.html with 200 for client-side routing)
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  price_class = "PriceClass_100" # Use lowest cost tier (US, Canada, Europe)

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Viewer Certificate
  viewer_certificate {
    cloudfront_default_certificate = var.domain_name == "" ? true : false
    acm_certificate_arn            = var.domain_name != "" ? aws_acm_certificate_validation.cf_cert[0].certificate_arn : null
    ssl_support_method             = var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = var.domain_name != "" ? "TLSv1.2_2021" : null
  }

  tags = {
    Name = "bm_cloudfront_dist"
  }
}
