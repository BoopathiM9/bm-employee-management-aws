# ============================================================
# EC2 LAUNCH TEMPLATE (bm_backend_lt)
# Requirements:
# - Amazon Linux 2023
# - IAM Instance Profile attached
# - Backend SG attached
# - No public IP address assigned
# - SSM Agent running (for AWS Systems Manager Session Manager)
# - User Data: Installs Node.js, configures systemd, starts app
# - NO passwords, database credentials, or access keys in User Data
# ============================================================
resource "aws_launch_template" "bm_backend_lt" {
  name_prefix   = "bm-backend-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.bm_ec2_instance_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.bm_backend_sg.id]
  }

  # User Data script executed at launch
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    echo "=== Starting BM Backend Instance Bootstrap ==="

    # Update packages
    dnf update -y

    # Install Node.js 20 LTS, git, unzip, and CloudWatch agent
    dnf install -y nodejs git unzip amazon-cloudwatch-agent

    # Ensure SSM Agent is running (pre-installed on AL2023)
    systemctl enable --now amazon-ssm-agent

    # Fetch backend artifact securely from S3
    mkdir -p /opt/bm-app/backend
    cd /opt/bm-app
    aws s3 cp s3://${aws_s3_bucket.bm_frontend_bucket.id}/deployments/backend.zip backend.zip
    unzip -o backend.zip -d /opt/bm-app/backend || true

    # Install production dependencies
    cd /opt/bm-app/backend
    npm install --omit=dev

    # Create ec2-user permissions
    chown -R ec2-user:ec2-user /opt/bm-app

    # Create systemd service unit
    cat <<SERVICE > /etc/systemd/system/bm-backend.service
    [Unit]
    Description=BM Employee Management Backend Node.js Service
    After=network.target

    [Service]
    Type=simple
    User=ec2-user
    WorkingDirectory=/opt/bm-app/backend
    ExecStart=/usr/bin/node src/server.js
    Restart=always
    RestartSec=5
    Environment=NODE_ENV=production
    Environment=PORT=8080
    Environment=USE_SECRETS_MANAGER=true
    Environment=SECRET_NAME=bm_db_credentials
    Environment=AWS_REGION=${var.aws_region}

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # Reload systemd and start application
    systemctl daemon-reload
    systemctl enable --now bm-backend

    echo "=== Bootstrap Completed Successfully ==="
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "bm_backend_instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
