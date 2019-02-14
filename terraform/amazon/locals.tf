locals {
  logical_name = "${replace(var.github_repository, "repostnetwork/", "")}"
  ecr_path = "${var.env == "production" ? "525699053407.dkr.ecr.us-east-1.amazonaws.com" : "757756428481.dkr.ecr.us-east-1.amazonaws.com"}"
  image_name = "${local.ecr_path}/${local.logical_name}:latest"
}