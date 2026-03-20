data "aws_caller_identity" "current" {}

data "aws_ecr_repository" "repo" {
  name = var.ecr_repo_name
}

module "network" {
  source  = "./modules/network"
  project = var.project
}

module "dns_acm" {
  source      = "./modules/dns_acm"
  domain_name = var.domain_name
  fqdn        = local.fqdn
}

module "alb" {
  source            = "./modules/alb"
  project           = var.project
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  certificate_arn   = module.dns_acm.certificate_arn
  container_port    = var.container_port
}

module "ecs" {
  source             = "./modules/ecs"
  project            = var.project
  region             = var.aws_region
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  alb_sg_id        = module.alb.alb_sg_id
  target_group_arn = module.alb.target_group_arn

  container_port = var.container_port
  cpu            = var.cpu
  memory         = var.memory

  image_uri      = "${data.aws_ecr_repository.repo.repository_url}:${var.image_tag}"
  log_group_name = local.log_group_name
}

module "monitoring" {
  source        = "./modules/monitoring"
  project       = var.project
  region        = var.aws_region
  cluster_name  = module.ecs.cluster_name
  service_name  = module.ecs.service_name
  lb_arn_suffix = module.alb.lb_arn_suffix
  tg_arn_suffix = module.alb.tg_arn_suffix

  cpu_alarm_threshold = var.cpu_alarm_threshold
  dashboard_json_path = "${path.module}/dashboard.json"
}

# Route53 alias record to ALB
resource "aws_route53_record" "app" {
  zone_id = module.dns_acm.zone_id
  name    = local.fqdn
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}