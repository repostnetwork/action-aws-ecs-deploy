data "aws_availability_zones" "available" {
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "default" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

data "aws_ecs_cluster" "main" {
  cluster_name = var.cluster_name
}

data "aws_iam_role" "task_container_role" {
  name = var.ecs_task_container_role
}

data "aws_iam_role" "task_execution_role" {
  name = var.ecs_task_execution_role
}

data "aws_ecr_repository" "main" {
  name = var.logical_name
}

data "aws_route53_zone" "selected" {
  name = local.aws_route53_zone_name
}

data "aws_acm_certificate" "main" {
  domain = local.domain_name
}

