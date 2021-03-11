resource "aws_wafv2_web_acl" "web_acl" {
  name  = "repost-ecs-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "block-public-actuator-traffic"
    priority = 1

    override_action {
      count {}
    }

    statement {
      byte_match_statement {
        field_to_match {
          uri_path {}
        }
        positional_constraint = "STARTS_WITH"
        search_string         = "/actuator/"
        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "block-public-actuator-endpoints-metrics"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "web-acl-metrics"
    sampled_requests_enabled   = false
  }
}