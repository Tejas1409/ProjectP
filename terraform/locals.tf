locals {
  fqdn           = "${var.app_subdomain}.${var.domain_name}"
  log_group_name = "/ecs/${var.project}"
}