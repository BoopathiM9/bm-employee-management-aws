# ============================================================
# RDS DB SUBNET GROUP (bm_db_subnet_group)
# Spans both private DB subnets across 2 AZs
# ============================================================
resource "aws_db_subnet_group" "bm_db_subnet_group" {
  name        = "bm_db_subnet_group"
  description = "Private database subnet group for BM PostgreSQL RDS"
  subnet_ids  = [
    aws_subnet.bm_private_db_subnet_1.id,
    aws_subnet.bm_private_db_subnet_2.id
  ]

  tags = {
    Name = "bm_db_subnet_group"
  }
}

# ============================================================
# RDS POSTGRESQL INSTANCE (bm_postgres_db)
# Requirements:
# - Multi-AZ
# - Private DB subnets
# - Public accessibility disabled
# - Encryption enabled
# - Automated backups enabled
# - Backup retention configured
# - Security group only allows 5432 from Backend-SG
# ============================================================
resource "aws_db_instance" "bm_postgres_db" {
  identifier        = "bm-postgres-db"
  engine            = "postgres"
  engine_version     = "16.3"
  instance_class    = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.bm_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.bm_db_sg.id]

  # Isolation & Redundancy
  publicly_accessible = false
  multi_az            = var.multi_az

  # Backups
  backup_retention_period   = var.db_backup_retention_days
  backup_window             = "03:00-04:00"
  maintenance_window        = "Mon:04:00-Mon:05:00"
  copy_tags_to_snapshot     = true
  delete_automated_backups  = true

  # Protection
  skip_final_snapshot       = true
  deletion_protection       = false

  tags = {
    Name = "bm_postgres_db"
  }
}
