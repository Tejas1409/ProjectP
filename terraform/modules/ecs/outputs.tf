output "cluster_name" { value = aws_ecs_cluster.cluster.name }
output "service_name" { value = aws_ecs_service.service.name }
output "task_family" { value = aws_ecs_task_definition.task.family }