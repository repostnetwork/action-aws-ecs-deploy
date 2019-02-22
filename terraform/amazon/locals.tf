locals {
  logical_name = "${replace(var.github_repository, "repostnetwork/", "")}"
  domain_name = "${var.env == "production" ? "repostnetwork.com" : "repostnetworktesting.com"}"
  aws_route53_zone_name = "${concat(local.domain_name, ".")}"
  aws_route53_record_name = "${concat(local.logical_name, ".services.", local.domain_name)}"
}