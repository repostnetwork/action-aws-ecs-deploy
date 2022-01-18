resource "aws_appautoscaling_target" "target" {
  count              = var.autoscaling_enabled == "true" ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.logical_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.autoscaling_min_capacity
  max_capacity       = var.autoscaling_max_capacity
  depends_on = [
    aws_ecs_service.web,
    aws_ecs_service.worker,
  ]
}

# Scale capacity up by one
resource "aws_appautoscaling_policy" "up" {
  count              = var.autoscaling_enabled == "true" ? 1 : 0
  name               = "${var.logical_name}-ecs-scale-up"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.target[0].resource_id
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.autoscaling_adjustment
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# Scale capacity down by one
resource "aws_appautoscaling_policy" "down" {
  count              = var.autoscaling_enabled == "true" ? 1 : 0
  name               = "${var.logical_name}-ecs-scale-down"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.target[0].resource_id
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.autoscaling_adjustment
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_metric_alarm_network_traffic_high" {
  count             = var.autoscaling_enabled == "true" && var.autoscaling_resource_type == "network" ? 1 : 0
  alarm_name        = "${var.logical_name}-RequestCountPerTarget-High"
  alarm_description = "Managed by Terraform"
  alarm_actions     = [aws_appautoscaling_policy.up[0].arn]

  # ok_actions          = ["${var.alarm_pagerduty_sns}"]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.autoscaling_alarm_evaluation_periods
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  period              = var.autoscaling_alarm_period
  statistic           = "Sum"
  threshold           = var.autoscaling_alarm_network_threshold_high
  datapoints_to_alarm = var.autoscaling_datapoints_to_alarm

  dimensions = {
    LoadBalancer = regex("targetgroup/.+/[a-z0-9]+", aws_alb_target_group.app[0].arn)
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_metric_alarm_network_traffic_low" {
  count             = var.autoscaling_enabled == "true" && var.autoscaling_resource_type == "network" ? 1 : 0
  alarm_name        = "${var.logical_name}-RequestCountPerTarget-Low"
  alarm_description = "Managed by Terraform"
  alarm_actions     = [aws_appautoscaling_policy.down[0].arn]

  # ok_actions          = ["${var.alarm_pagerduty_sns}"]
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.autoscaling_alarm_evaluation_periods
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  period              = var.autoscaling_alarm_period
  statistic           = "Sum"
  threshold           = var.autoscaling_alarm_network_threshold_low
  datapoints_to_alarm = var.autoscaling_datapoints_to_alarm

  dimensions = {
    LoadBalancer = regex("targetgroup/.+/[a-z0-9]+", aws_alb_target_group.app[0].arn)
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_metric_alarm_rpm_high" {
  count             = var.autoscaling_enabled == "true" && var.autoscaling_resource_type == "cpu" ? 1 : 0
  alarm_name        = "${var.logical_name}-CPUUtilization-High"
  alarm_description = "Managed by Terraform"
  alarm_actions     = [aws_appautoscaling_policy.up[0].arn]

  # ok_actions          = ["${var.alarm_pagerduty_sns}"]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.autoscaling_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.autoscaling_alarm_period
  statistic           = var.autoscaling_alarm_statistic
  threshold           = var.autoscaling_alarm_threshold_high
  datapoints_to_alarm = var.autoscaling_datapoints_to_alarm

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.logical_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_metric_alarm_rpm_low" {
  count             = var.autoscaling_enabled == "true" && var.autoscaling_resource_type == "cpu" ? 1 : 0
  alarm_name        = "${var.logical_name}-CPUUtilization-Low"
  alarm_description = "Managed by Terraform"
  alarm_actions     = [aws_appautoscaling_policy.down[0].arn]

  # ok_actions          = ["${var.alarm_pagerduty_sns}"]
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.autoscaling_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.autoscaling_alarm_period
  statistic           = var.autoscaling_alarm_statistic
  threshold           = var.autoscaling_alarm_threshold_low
  datapoints_to_alarm = var.autoscaling_datapoints_to_alarm

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.logical_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_metric_alarm_queue_age_high" {
  count             = var.autoscaling_enabled == "true" && var.autoscaling_resource_type == "queue" ? 1 : 0
  alarm_name        = "${var.logical_name}-ApproximateAgeOfOldestMessage-High"
  alarm_description = "Managed by Terraform"
  alarm_actions     = [aws_appautoscaling_policy.up[0].arn]

  # ok_actions          = ["${var.alarm_pagerduty_sns}"]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.autoscaling_alarm_evaluation_periods
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = var.autoscaling_alarm_period
  statistic           = var.autoscaling_alarm_statistic
  threshold           = var.autoscaling_alarm_threshold_high
  datapoints_to_alarm = var.autoscaling_datapoints_to_alarm

  dimensions = {
    QueueName = var.autoscaling_queue_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_metric_alarm_queue_age_low" {
  count             = var.autoscaling_enabled == "true" && var.autoscaling_resource_type == "queue" ? 1 : 0
  alarm_name        = "${var.logical_name}-ApproximateAgeOfOldestMessage-Low"
  alarm_description = "Managed by Terraform"
  alarm_actions     = [aws_appautoscaling_policy.down[0].arn]

  # ok_actions          = ["${var.alarm_pagerduty_sns}"]
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.autoscaling_alarm_evaluation_periods
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = var.autoscaling_alarm_period
  statistic           = var.autoscaling_alarm_statistic
  threshold           = var.autoscaling_alarm_threshold_low
  datapoints_to_alarm = var.autoscaling_datapoints_to_alarm

  dimensions = {
    QueueName = var.autoscaling_queue_name
  }
}

