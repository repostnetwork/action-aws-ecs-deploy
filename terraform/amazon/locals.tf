locals {
  domain_name = "${var.env == "production" ? "repostnetwork.com" : "repostnetworktesting.com"}"
  aws_route53_zone_name = "${local.domain_name}."
  aws_route53_record_name = "${var.logical_name}.services.${local.domain_name}"
}