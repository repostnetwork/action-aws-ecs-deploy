##########################
# Networking
##########################

# Fetch AZs in the current region


##########################
# Security Groups
##########################

# ALB Security group
# This is the group you need to edit if you want to restrict access to your application
resource "aws_security_group" "lb" {
  name = "${local.logical_name}-lb"
  description = "controls access to the ALB"
  vpc_id = "${data.aws_vpc.default.id}"

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

# Traffic to the ECS Cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  name = "${local.logical_name}"
  description = "allow inbound access from the ALB only"
  vpc_id = "${data.aws_vpc.default.id}"

  ingress {
    protocol = "tcp"
    from_port = "${var.port}"
    to_port = "${var.port}"
    security_groups = [
      "${aws_security_group.lb.id}"]
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

##########################
# Load Balancer
##########################

resource "aws_alb" "main" {
  load_balancer_type = "application"
  name = "${local.logical_name}-lb"
  subnets = [
    "${data.aws_subnet.default.*.id}"]
  security_groups = [
    "${aws_security_group.lb.id}"]
}

resource "aws_alb_target_group" "app" {
  port = 80
  protocol = "HTTP"
  vpc_id = "${data.aws_vpc.default.id}"
  target_type = "ip"
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "${aws_alb.main.id}"
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.app.id}"
    type = "forward"
  }
}


##########################
# ECR & ECS
##########################

resource "aws_ecs_task_definition" "main" {
  family = "${local.logical_name}"
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"]
  cpu = "${var.cpu}"
  memory = "${var.memory}"
  task_role_arn = "${data.aws_iam_role.task_container_role.arn}"
  execution_role_arn = "${data.aws_iam_role.task_execution_role.arn}"

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.cpu},
    "image": "${data.aws_ecr_repository.main.repository_url}:latest",
    "memory": ${var.memory},
    "name": "${local.logical_name}",
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
      "awslogs-group": "ecs/${local.logical_name}",
      "awslogs-region": "${var.region}",
      "awslogs-stream-prefix": "${local.logical_name}"
      }
    },
    "healthCheck": {
      "command": "CMD-SHELL,curl -f http://localhost:8080/actuator/health || exit 1",
      "interval": "30",
      "timeout" : "5",
      "retries" : "3",
      "startPeriod" : "60"
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

resource "aws_ecs_service" "main" {
  name = "${local.logical_name}"
  cluster = "${data.aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.main.arn}"
  desired_count = "${var.container_count}"
  launch_type = "FARGATE"
  health_check_grace_period_seconds = 10
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent = 200

  network_configuration {
    security_groups = [
      "${aws_security_group.ecs_tasks.id}"]
    subnets = [
      "${data.aws_subnet.default.*.id}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.app.id}"
    container_name = "${local.logical_name}"
    container_port = "${var.port}"
  }

  depends_on = [
    "aws_alb_listener.front_end",
  ]
}
