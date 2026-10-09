# ============================================================
# VPC
# ============================================================
resource "aws_vpc" "bm_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "bm_vpc"
  }
}

# ============================================================
# Internet Gateway
# ============================================================
resource "aws_internet_gateway" "bm_igw" {
  vpc_id = aws_vpc.bm_vpc.id

  tags = {
    Name = "bm_igw"
  }
}

# ============================================================
# PUBLIC SUBNETS (for ALB and NAT Gateway)
# ============================================================
resource "aws_subnet" "bm_public_subnet_1" {
  vpc_id                  = aws_vpc.bm_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.az_1
  map_public_ip_on_launch = true

  tags = {
    Name = "bm_public_subnet_1"
    Type = "public"
  }
}

resource "aws_subnet" "bm_public_subnet_2" {
  vpc_id                  = aws_vpc.bm_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.az_2
  map_public_ip_on_launch = true

  tags = {
    Name = "bm_public_subnet_2"
    Type = "public"
  }
}

# ============================================================
# PRIVATE APPLICATION SUBNETS (for Backend EC2 - NO public IP)
# ============================================================
resource "aws_subnet" "bm_private_app_subnet_1" {
  vpc_id                  = aws_vpc.bm_vpc.id
  cidr_block              = var.private_app_subnet_1_cidr
  availability_zone       = var.az_1
  map_public_ip_on_launch = false

  tags = {
    Name = "bm_private_app_subnet_1"
    Type = "private-app"
  }
}

resource "aws_subnet" "bm_private_app_subnet_2" {
  vpc_id                  = aws_vpc.bm_vpc.id
  cidr_block              = var.private_app_subnet_2_cidr
  availability_zone       = var.az_2
  map_public_ip_on_launch = false

  tags = {
    Name = "bm_private_app_subnet_2"
    Type = "private-app"
  }
}

# ============================================================
# PRIVATE DATABASE SUBNETS (for RDS - completely isolated)
# ============================================================
resource "aws_subnet" "bm_private_db_subnet_1" {
  vpc_id                  = aws_vpc.bm_vpc.id
  cidr_block              = var.private_db_subnet_1_cidr
  availability_zone       = var.az_1
  map_public_ip_on_launch = false

  tags = {
    Name = "bm_private_db_subnet_1"
    Type = "private-db"
  }
}

resource "aws_subnet" "bm_private_db_subnet_2" {
  vpc_id                  = aws_vpc.bm_vpc.id
  cidr_block              = var.private_db_subnet_2_cidr
  availability_zone       = var.az_2
  map_public_ip_on_launch = false

  tags = {
    Name = "bm_private_db_subnet_2"
    Type = "private-db"
  }
}

# ============================================================
# ELASTIC IP for NAT Gateway
# ============================================================
resource "aws_eip" "bm_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "bm_nat_eip"
  }

  depends_on = [aws_internet_gateway.bm_igw]
}

# ============================================================
# NAT GATEWAY (in public subnet 1 - allows private EC2 outbound internet)
# ============================================================
resource "aws_nat_gateway" "bm_nat_gw" {
  allocation_id = aws_eip.bm_nat_eip.id
  subnet_id     = aws_subnet.bm_public_subnet_1.id

  tags = {
    Name = "bm_nat_gw"
  }

  depends_on = [aws_internet_gateway.bm_igw]
}

# ============================================================
# ROUTE TABLES
# ============================================================

# Public Route Table → Internet Gateway
resource "aws_route_table" "bm_public_rt" {
  vpc_id = aws_vpc.bm_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bm_igw.id
  }

  tags = {
    Name = "bm_public_rt"
  }
}

# Private App Route Table → NAT Gateway (outbound only)
resource "aws_route_table" "bm_private_app_rt" {
  vpc_id = aws_vpc.bm_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.bm_nat_gw.id
  }

  tags = {
    Name = "bm_private_app_rt"
  }
}

# Private DB Route Table → NO internet access
resource "aws_route_table" "bm_private_db_rt" {
  vpc_id = aws_vpc.bm_vpc.id

  tags = {
    Name = "bm_private_db_rt"
  }
}

# ============================================================
# ROUTE TABLE ASSOCIATIONS
# ============================================================

# Public subnets → Public route table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.bm_public_subnet_1.id
  route_table_id = aws_route_table.bm_public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.bm_public_subnet_2.id
  route_table_id = aws_route_table.bm_public_rt.id
}

# Private app subnets → Private app route table (via NAT)
resource "aws_route_table_association" "private_app_1" {
  subnet_id      = aws_subnet.bm_private_app_subnet_1.id
  route_table_id = aws_route_table.bm_private_app_rt.id
}

resource "aws_route_table_association" "private_app_2" {
  subnet_id      = aws_subnet.bm_private_app_subnet_2.id
  route_table_id = aws_route_table.bm_private_app_rt.id
}

# Private DB subnets → Private DB route table (no internet)
resource "aws_route_table_association" "private_db_1" {
  subnet_id      = aws_subnet.bm_private_db_subnet_1.id
  route_table_id = aws_route_table.bm_private_db_rt.id
}

resource "aws_route_table_association" "private_db_2" {
  subnet_id      = aws_subnet.bm_private_db_subnet_2.id
  route_table_id = aws_route_table.bm_private_db_rt.id
}
