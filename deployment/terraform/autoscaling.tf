# ============================================================
# AUTO SCALING GROUP (bm_backend_asg)
# Requirements:
# - Minimum: 2
# - Desired: 2
# - Maximum: 4
# - Instances distributed across AZ-1 (PrivateAppSubnet1) and AZ-2 (PrivateAppSubnet2)
# - Attached to Target Group (BackendTargetGroup)
# - Health check type: ELB
# - Automatic instance replacement if unhealthy
# ============================================================
resource "aws_autoscaling_group" "bm_backend_asg" {
  name_prefix         = "bm-backend-asg-"
  vpc_zone_identifier = [
    aws_subnet.bm_private_app_subnet_1.id,
    aws_subnet.bm_private_app_subnet_2.id
  ]

  min_size         = var.asg_min_size
  desired_capacity = var.asg_desired_capacity
  max_size         = var.asg_max_size

  target_group_arns = [aws_lb_target_group.bm_backend_tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 600

  force_delete          = true
  wait_for_capacity_timeout = "10m"

  launch_template {
    id      = aws_launch_template.bm_backend_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "bm_backend_instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "bm_employee_management"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  depends_on = [
    aws_nat_gateway.bm_nat_gw,
    aws_lb.bm_alb,
    aws_lb_target_group.bm_backend_tg
  ]
}
