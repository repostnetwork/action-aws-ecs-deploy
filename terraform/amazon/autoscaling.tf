
variable "autoscale_enabled" {
  description = "Setup autoscale."
  default     = "false"
}

variable "autoscale_rpm_enabled" {
  description = "Setup autoscale for RPM."
  default     = "false"
}

variable "alarm_rpm_high_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  default     = "3"
}

variable "alarm_rpm_high_period" {
  description = "The period in seconds over which the specified statistic is applied."
  default     = "60"
}

variable "alarm_rpm_high_statistic" {
  description = "The statistic to apply to the alarm's associated metric. Either of the following is supported: SampleCount, Average, Sum, Minimum, Maximum"
  default     = "Average"
}

variable "alarm_rpm_high_threshold" {
  description = "The value against which the specified statistic is compared."
  default     = "80"
}

variable "alarm_rpm_low_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  default     = "10"
}

variable "alarm_rpm_low_period" {
  description = "The period in seconds over which the specified statistic is applied."
  default     = "60"
}

variable "alarm_rpm_low_statistic" {
  description = "The statistic to apply to the alarm's associated metric. Either of the following is supported: SampleCount, Average, Sum, Minimum, Maximum"
  default     = "Average"
}

variable "alarm_rpm_low_threshold" {
  description = "The value against which the specified statistic is compared."
  default     = "60"
}

variable "autoscale_max_capacity" {
  description = "Max containers count for autoscale."
  default     = "4"
}

variable "autoscale_down_rpm_cooldown" {
  description = "Seconds between scaling actions."
  default     = "300"
}

variable "autoscale_down_rpm_aggregation_type" {
  description = "Valid values are Minimum, Maximum, and Average."
  default     = "Average"
}

variable "autoscale_down_rpm_interval_upper_bound" {
  description = "Difference between the alarm threshold and the CloudWatch metric."
  default     = "0"
}

variable "autoscale_down_rpm_adjustment" {
  default = "-1"
}

variable "alarm_pagerduty_sns" {
  default = ""
}


# CloudWatch alarm for scaling up
resource "aws_cloudwatch_metric_alarm" "cloudwatch_metric_alarm_rpm_high" {
  count               = "${var.autoscale_rpm_enabled == "true" ? 1 : 0}"
  alarm_name          = "${local.logical_name}-ECSServiceAverageCPUUtilization-High"
  alarm_description   = "Alarm for scaling up ${local.logical_name} ecs"
  alarm_actions       = ["${aws_appautoscaling_policy.appautoscaling_policy_rpm_scale_up.arn}", "${var.alarm_pagerduty_sns}"]
  ok_actions          = ["${var.alarm_pagerduty_sns}"]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.alarm_rpm_high_evaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "${var.alarm_rpm_high_period}"
  statistic           = "${var.alarm_rpm_high_statistic}"
  threshold           = "${var.alarm_rpm_high_threshold}"

  dimensions {
    clusterName = "${var.cluster_name}"
    TargetGroup  = "${aws_alb_target_group.app.arn_suffix}"
  }
}

# CloudWatch alarm for scaling down
resource "aws_cloudwatch_metric_alarm" "cloudwatch_metric_alarm_rpm_low" {
  count               = "${var.autoscale_rpm_enabled == "true" ? 1 : 0}"
  alarm_name          = "${local.logical_name}-RequestCountPerTarget-Low"
  alarm_description   = "Alarm for scaling down ${local.logical_name} ecs"
  alarm_actions       = ["${aws_appautoscaling_policy.appautoscaling_policy_rpm_scale_down.arn}", "${var.alarm_pagerduty_sns}"]
  ok_actions          = ["${var.alarm_pagerduty_sns}"]
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "${var.alarm_rpm_low_evaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "${var.alarm_rpm_low_period}"
  statistic           = "${var.alarm_rpm_low_statistic}"
  threshold           = "${var.alarm_rpm_low_threshold}"

  dimensions {
    LoadBalancer = "${var.alb_listener_arn}"
    TargetGroup  = "${aws_alb_target_group.alb_target_group.arn_suffix}"
  }
}

resource "aws_autoscaling_policy" "bat" {
  name                   = "${local.logical_name}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = "${local.logical_name}"
}

# Autoscaling Target
resource "aws_appautoscaling_target" "appautoscaling_target" {
  count              = "${var.autoscale_enabled == "true" ? 1 : 0}"
  max_capacity       = "${var.autoscale_max_capacity}"
  min_capacity       = "${var.service_desired_count}"
  resource_id        = "service/${var.cluster}/${var.name}"
  role_arn           = "arn:aws:iam::${var.account_id}:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
