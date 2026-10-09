# ============================================================
# S3 BUCKET FOR REACT FRONTEND (bm-frontend-app)
# Requirements:
# - S3 Block Public Access enabled
# - Bucket must NOT be publicly accessible
# - No direct S3 website access
# - CloudFront must access S3 via Origin Access Control (OAC)
# ============================================================
resource "aws_s3_bucket" "bm_frontend_bucket" {
  bucket_prefix = "bm-frontend-app-"
  force_destroy = true

  tags = {
    Name = "bm_frontend_bucket"
  }
}

# Block all public access - strictly private
resource "aws_s3_bucket_public_access_block" "bm_frontend_pab" {
  bucket = aws_s3_bucket.bm_frontend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "bm_frontend_versioning" {
  bucket = aws_s3_bucket.bm_frontend_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Server-Side Encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "bm_frontend_encryption" {
  bucket = aws_s3_bucket.bm_frontend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Policy: Only allow CloudFront OAC to read objects
resource "aws_s3_bucket_policy" "bm_frontend_bucket_policy" {
  bucket = aws_s3_bucket.bm_frontend_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.bm_frontend_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.bm_cloudfront_dist.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.bm_frontend_pab]
}

# Backend deployment package
resource "aws_s3_object" "backend_bundle" {
  bucket = aws_s3_bucket.bm_frontend_bucket.id
  key    = "deployments/backend.zip"
  source = "${path.module}/../backend.zip"
  etag   = filemd5("${path.module}/../backend.zip")
}
