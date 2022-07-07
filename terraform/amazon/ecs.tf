resource "aws_ecs_task_definition" "main" {
  count        = var.use_efs ? 0 : 1
  family       = var.logical_name
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]
  cpu                = var.cpu
  memory             = var.memory
  task_role_arn      = data.aws_iam_role.task_container_role.arn
  execution_role_arn = data.aws_iam_role.task_execution_role.arn

  container_definitions = templatefile("${path.module}/task-definitions/main.tftpl", local.main_vars)
}

resource "aws_ecs_task_definition" "efs" {
  count        = var.use_efs ? 1 : 0
  family       = var.logical_name
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]
  cpu                = var.cpu
  memory             = var.memory
  task_role_arn      = data.aws_iam_role.task_container_role.arn
  execution_role_arn = data.aws_iam_role.task_execution_role.arn

  container_definitions = templatefile("${path.module}/task-definitions/main-efs.tftpl", local.main_efs_vars)

  volume {
    name = var.efs_name
    efs_volume_configuration {
      file_system_id          = var.efs_file_system_id
      root_directory          = var.efs_path
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
      authorization_config {
        access_point_id   = var.efs_access_point_id
        iam               = "ENABLED"
      }
    }
  }
}

output "aws_ecs_task_definition_arn" {
  value = "${element(concat(aws_ecs_task_definition.main.*.arn, aws_ecs_task_definition.efs.*.arn, list("")), 0)}"
}

resource "aws_ecs_service" "web" {
  count = var.is_worker ? 0 : 1 # no load balancer if worker
  name = var.logical_name
  cluster = data.aws_ecs_cluster.main.id
  task_definition = output.aws_ecs_task_definition_arn
  desired_count = var.container_count
  launch_type = "FARGATE"
  health_check_grace_period_seconds = var.health_check_grace_period
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent = var.max_healthy_percent

  network_configuration {
    security_groups = [
      aws_security_group.ecs_tasks.id,
    ]
    subnets = data.aws_subnet_ids.default.ids
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
  task_definition = output.aws_ecs_task_definition_arn
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
    subnets = data.aws_subnet_ids.default.ids
    assign_public_ip = true
  }
}
