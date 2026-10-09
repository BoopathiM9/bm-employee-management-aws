# ============================================================
# CLOUDWATCH LOG GROUP (bm_backend_logs)
# Stores centralized logs from backend EC2 instances
# ============================================================
resource "aws_cloudwatch_log_group" "bm_backend_logs" {
  name              = "/aws/ec2/bm_backend_logs"
  retention_in_days = 14

  tags = {
    Name = "bm_backend_logs"
  }
}

# ============================================================
# CLOUDWATCH ALARM 1: ALB HTTP 5XX Errors > 10 in 5 minutes
# Sends alert to SNS topic bm_production_alerts
# ============================================================
resource "aws_cloudwatch_metric_alarm" "bm_alb_5xx_alarm" {
  alarm_name          = "bm_alb_5xx_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Triggers when ALB target group reports more than 10 HTTP 5xx responses in 5 minutes"

  dimensions = {
    LoadBalancer = aws_lb.bm_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.bm_backend_tg.arn_suffix
  }

  alarm_actions = [aws_sns_topic.bm_production_alerts.arn]
  ok_actions    = [aws_sns_topic.bm_production_alerts.arn]

  tags = {
    Name = "bm_alb_5xx_alarm"
  }
}

# ============================================================
# CLOUDWATCH ALARM 2: EC2 Auto Scaling Average CPU > 80%
# ============================================================
resource "aws_cloudwatch_metric_alarm" "bm_ec2_cpu_alarm" {
  alarm_name          = "bm_ec2_cpu_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when Auto Scaling Group average CPU utilization exceeds 80% for 10 minutes"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.bm_backend_asg.name
  }

  alarm_actions = [aws_sns_topic.bm_production_alerts.arn]

  tags = {
    Name = "bm_ec2_cpu_alarm"
  }
}

# ============================================================
# CLOUDWATCH ALARM 3: RDS PostgreSQL CPU > 80%
# ============================================================
resource "aws_cloudwatch_metric_alarm" "bm_rds_cpu_alarm" {
  alarm_name          = "bm_rds_cpu_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when RDS PostgreSQL CPU utilization exceeds 80% for 10 minutes"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.bm_postgres_db.identifier
  }

  alarm_actions = [aws_sns_topic.bm_production_alerts.arn]

  tags = {
    Name = "bm_rds_cpu_alarm"
  }
}
