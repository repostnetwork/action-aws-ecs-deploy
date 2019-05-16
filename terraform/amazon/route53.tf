resource "aws_route53_record" "main" {
  count = "${var.is_worker ? 0 : 1}" # no cname if worker
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${local.aws_route53_record_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_alb.main.dns_name}"]
}