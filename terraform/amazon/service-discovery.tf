resource "aws_service_discovery_service" "internal" {
  name = substr(var.logical_name, 0, min(length(var.logical_name), 32))
  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = 10
      type = "SRV"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

