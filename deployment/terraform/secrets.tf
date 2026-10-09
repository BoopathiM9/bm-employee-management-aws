# ============================================================
# RDS PASSWORD - Generated Randomly (never hardcoded)
# ============================================================
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%^&*()-_=+[]{}|"
}

# ============================================================
# AWS SECRETS MANAGER - bm_db_credentials
# Stores all DB credentials securely. EC2 reads this at runtime.
# NEVER committed to code, Git, .env, or AMI.
# ============================================================
resource "aws_secretsmanager_secret" "bm_db_credentials" {
  name        = "bm_db_credentials"
  description = "PostgreSQL RDS credentials for BM Employee Management application"

  # Prevent accidental deletion in production
  recovery_window_in_days = 7

  tags = {
    Name = "bm_db_credentials"
  }
}

resource "aws_secretsmanager_secret_version" "bm_db_credentials_version" {
  secret_id = aws_secretsmanager_secret.bm_db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.bm_postgres_db.address
    port     = 5432
    dbname   = var.db_name
    engine   = "postgres"
  })

  depends_on = [aws_db_instance.bm_postgres_db]
}
