resource "aws_alb" "main" {
  count              = var.is_worker ? 0 : 1 # no load balancer if worker
  load_balancer_type = "application"
  name               = "${var.logical_name}-lb"
  subnets            = data.aws_subnet.default.*.id
  security_groups = [
    aws_security_group.lb.id,
  ]
  idle_timeout = var.idle_timeout
}

resource "aws_alb_target_group" "app" {
  count       = var.is_worker ? 0 : 1 # no load balancer if worker
  name        = substr(var.logical_name, 0, min(length(var.logical_name), 32))
  port        = var.port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
  health_check {
    path     = var.health_check_endpoint
    port     = var.port
    interval = 45
  }
}

resource "aws_alb_listener" "https" {
  count             = var.is_worker ? 0 : 1 # no cname if worker
  load_balancer_arn = aws_alb.main[0].id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.main.arn

  default_action {
    target_group_arn = aws_alb_target_group.app[0].id
    type             = "forward"
  }
}

resource "aws_wafv2_web_acl_association" "web_acl_association" {
  count        = var.is_worker ? 0 : 1 # no load balancer if worker
  resource_arn = aws_alb.main[0].arn
  web_acl_arn  = var.waf_arn
}

