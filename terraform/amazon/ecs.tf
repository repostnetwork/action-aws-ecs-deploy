resource "aws_ecs_task_definition" "main" {
  family       = var.logical_name
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]
  cpu                = var.cpu
  memory             = var.memory
  task_role_arn      = data.aws_iam_role.task_container_role.arn
  execution_role_arn = data.aws_iam_role.task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "cpu": 0,
    "image": "${data.aws_ecr_repository.main.repository_url}:${var.tag}",
    "ephemeralStorage": {
      "sizeInGiB": ${var.volume_size}
    },
    "name": "${var.logical_name}",
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
      "awslogs-group": "ecs/${var.logical_name}",
      "awslogs-region": "${var.region}",
      "awslogs-stream-prefix": "${var.logical_name}"
      }
    },
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -f http://localhost:${var.port}${var.health_check_endpoint} || exit 1"],
      "interval": 45,
      "timeout" : 5,
      "retries" : 3,
      "startPeriod" : ${var.health_check_grace_period}
    },
    "portMappings": [
      {
        "containerPort": ${var.port},
        "hostPort": ${var.port}
      }
    ]
  }
]
DEFINITION

}

resource "aws_ecs_service" "web" {
  count = var.is_worker ? 0 : 1 # no load balancer if worker
  name = var.logical_name
  cluster = data.aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count = var.container_count
  launch_type = "FARGATE"
  health_check_grace_period_seconds = var.health_check_grace_period
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent = var.max_healthy_percent

  network_configuration {
    security_groups = [
      aws_security_group.ecs_tasks.id,
    ]
    subnets = data.aws_subnets.default.ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app[0].id
    container_name = var.logical_name
    container_port = var.port
  }

  service_registries {
    port = var.port
    registry_arn = aws_service_discovery_service.internal.arn
  }

  depends_on = [aws_alb_listener.https]
}

resource "aws_ecs_service" "worker" {
  count = var.is_worker ? 1 : 0 # no load balancer if worker
  name = var.logical_name
  cluster = data.aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count = var.container_count
  launch_type = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent = var.max_healthy_percent

  lifecycle {
    ignore_changes = [desired_count]
  }

  service_registries {
    port = var.port
    registry_arn = aws_service_discovery_service.internal.arn
  }

  network_configuration {
    security_groups = [
      aws_security_group.ecs_tasks.id,
    ]
    subnets = data.aws_subnets.default.ids
    assign_public_ip = true
  }
}

