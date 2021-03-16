resource "aws_service_discovery_private_dns_namespace" "internal_dns" {
  name        = "service.${var.env}"
  description = "Service Discovery for Internal Services"
  vpc         = data.aws_vpc.default.id
}

resource "aws_service_discovery_service" "internal" {
  name = substr(var.logical_name, 0, min(length(var.logical_name), 32))
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal_dns.id

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
