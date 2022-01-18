locals {
  domain_name             = var.domain_name != "default" ? var.domain_name : var.env == "production" ? "repostnetwork.com" : var.env == "web" ? "repostnetworktest.com" : "repostnetworktesting.com"
  aws_route53_zone_name   = "${local.domain_name}."
  aws_route53_record_name = "${var.logical_name}.services.${local.domain_name}"
}

