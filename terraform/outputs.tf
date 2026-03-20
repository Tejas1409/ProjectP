output "app_url" {
  value = "https://${local.fqdn}"
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "ecs_cluster" {
  value = module.ecs.cluster_name
}

output "ecs_service" {
  value = module.ecs.service_name
}

output "task_family" {
  value = module.ecs.task_family
}

output "ecr_repo_url" {
  value = data.aws_ecr_repository.repo.repository_url
}