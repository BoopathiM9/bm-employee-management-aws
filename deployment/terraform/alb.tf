# ============================================================
# APPLICATION LOAD BALANCER (bm_alb)
# Internet-facing, distributed across Public Subnet 1 & 2
# ============================================================
resource "aws_lb" "bm_alb" {
  name               = "bm-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.bm_alb_sg.id]
  subnets            = [
    aws_subnet.bm_public_subnet_1.id,
    aws_subnet.bm_public_subnet_2.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "bm_alb"
  }
}

# ============================================================
# TARGET GROUP (bm_backend_tg)
# Protocol: HTTP, Port: 8080, Health check: /health
# ============================================================
resource "aws_lb_target_group" "bm_backend_tg" {
  name        = "bm-backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.bm_vpc.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "8080"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "bm_backend_tg"
  }
}

# ============================================================
# HTTP LISTENER (Port 80)
# If no custom domain/certificate: forwards directly to backend TG
# If custom domain provided: redirects HTTP to HTTPS port 443
# ============================================================
resource "aws_lb_listener" "bm_alb_http_listener" {
  load_balancer_arn = aws_lb.bm_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.domain_name != "" ? "redirect" : "forward"

    target_group_arn = var.domain_name == "" ? aws_lb_target_group.bm_backend_tg.arn : null

    dynamic "redirect" {
      for_each = var.domain_name != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  tags = {
    Name = "bm_alb_http_listener"
  }
}

# ============================================================
# HTTPS LISTENER (Port 443) - enabled when domain_name is provided
# ============================================================
resource "aws_lb_listener" "bm_alb_https_listener" {
  count             = var.domain_name != "" ? 1 : 0
  load_balancer_arn = aws_lb.bm_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.alb_cert[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bm_backend_tg.arn
  }

  tags = {
    Name = "bm_alb_https_listener"
  }
}
