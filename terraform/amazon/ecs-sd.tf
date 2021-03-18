# TODO: Remove once cut over is complete
resource "aws_ecs_service" "web-service" {
  count = "${var.is_worker ? 0 : 1}" # no load balancer if worker
  name = "${var.logical_name}-${var.env}"
  cluster = "${data.aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.main.arn}"
  desired_count = "${var.container_count}"
  launch_type = "FARGATE"
  health_check_grace_period_seconds = 120
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent = "${var.max_healthy_percent}"

  network_configuration {
    security_groups = [
      "${aws_security_group.ecs_tasks.id}"]
    subnets = [
      "${data.aws_subnet.default.*.id}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.app.id}"
    container_name = "${var.logical_name}"
    container_port = "${var.port}"
  }
  service_registries {
    port = "${var.port}"
    registry_arn = "${aws_service_discovery_service.internal.arn}"
  }

  depends_on = [
    "aws_alb_listener.https"
  ]
}

resource "aws_ecs_service" "worker-service" {
  count = "${var.is_worker ? 1 : 0}" # no load balancer if worker
  name = "${var.logical_name}-${var.env}"
  cluster = "${data.aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.main.arn}"
  desired_count = "${var.container_count}"
  launch_type = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent = "${var.max_healthy_percent}"

  lifecycle {
    ignore_changes = ["desired_count"]
  }

  service_registries {
    registry_arn = "${aws_service_discovery_service.internal.arn}"
    port = "${var.port}"
  }

  network_configuration {
    security_groups = [
      "${aws_security_group.ecs_tasks.id}"]
    subnets = [
      "${data.aws_subnet.default.*.id}"]
    assign_public_ip = true
  }
}
