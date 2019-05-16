resource "aws_security_group" "lb" {
  name = "${var.logical_name}-lb"
  description = "controls access to the ALB"
  vpc_id = "${data.aws_vpc.default.id}"

  ingress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    ipv6_cidr_blocks = [
      "::/0"
    ]
  }

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

# Traffic to the ECS Cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  name = "${var.logical_name}"
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