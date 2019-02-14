output "alb_hostname" {
  value = "${aws_alb.main.dns_name}"
}

output "image_name" {
  value = "${local.image_name}"
}