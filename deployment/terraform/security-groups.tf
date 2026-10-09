# ============================================================
# ALB Security Group (bm_alb_sg)
# Public-facing: accepts HTTP 80 and HTTPS 443 from anywhere
# ============================================================
resource "aws_security_group" "bm_alb_sg" {
  name        = "bm_alb_sg"
  description = "Security group for Application Load Balancer - allows HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.bm_vpc.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound to backend"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bm_alb_sg"
  }
}

# ============================================================
# Backend Security Group (bm_backend_sg)
# Private: ONLY accepts port 8080 from ALB security group
# NO 0.0.0.0/0 → 8080
# ============================================================
resource "aws_security_group" "bm_backend_sg" {
  name        = "bm_backend_sg"
  description = "Security group for backend EC2 - only accepts traffic from ALB"
  vpc_id      = aws_vpc.bm_vpc.id

  ingress {
    description     = "Backend API port - only from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.bm_alb_sg.id]
  }

  egress {
    description = "Allow all outbound (for NAT gateway, Secrets Manager, RDS)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bm_backend_sg"
  }
}

# ============================================================
# Database Security Group (bm_db_sg)
# Private: ONLY accepts PostgreSQL 5432 from Backend SG
# NO 0.0.0.0/0 → 5432
# ============================================================
resource "aws_security_group" "bm_db_sg" {
  name        = "bm_db_sg"
  description = "Security group for RDS PostgreSQL - only accepts from backend EC2"
  vpc_id      = aws_vpc.bm_vpc.id

  ingress {
    description     = "PostgreSQL - only from backend EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bm_backend_sg.id]
  }

  egress {
    description = "Allow outbound within VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "bm_db_sg"
  }
}
