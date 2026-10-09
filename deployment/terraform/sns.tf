# ============================================================
# AMAZON SNS (bm_production_alerts)
# Alert notification topic for CloudWatch alarms
# ============================================================
resource "aws_sns_topic" "bm_production_alerts" {
  name         = "bm_production_alerts"
  display_name = "BM Production Alerts"

  tags = {
    Name = "bm_production_alerts"
  }
}

# Optional Email Subscription (requires user confirmation via email link)
resource "aws_sns_topic_subscription" "email_subscription" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.bm_production_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
