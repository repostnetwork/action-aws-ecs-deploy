data "aws_availability_zones" "available" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_service_discovery_private_dns_namespace" "internal_dns" {
  name = "service.${var.env}"
}

data "aws_subnet_ids" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
}

data "aws_subnet" "default" {
  count = "${length(data.aws_subnet_ids.default.ids)}"
  id    = "${data.aws_subnet_ids.default.ids[count.index]}"
}

data "aws_ecs_cluster" "main" {
  cluster_name = "${var.cluster_name}"
}

data "aws_iam_role" "task_container_role" {
  name = "${var.ecs_task_container_role}"
}

data "aws_iam_role" "task_execution_role" {
  name = "${var.ecs_task_execution_role}"
}

data "aws_ecr_repository" "main" {
  name = "${var.logical_name}"
}

data "aws_route53_zone" "selected" {
  name = "${local.aws_route53_zone_name}"
}

data "aws_acm_certificate" "main" {
  domain = "${local.domain_name}"
}
