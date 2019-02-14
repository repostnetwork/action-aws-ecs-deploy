locals {
  logical_name = "${replace(var.github_repository, "repostnetwork/", "")}"
}