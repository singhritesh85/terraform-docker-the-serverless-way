output "ecs_cluster_name" {
  description = "The name of the created ECS cluster."
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "task_definition_arn_bankapp" {
  description = "Full ARN of the Task Definition (including both family and revision)."
  value       = aws_ecs_task_definition.ecs_task_definition.arn
}

output "task_definition_arn_mysql" {
  description = "Full ARN of the Task Definition (including both family and revision)."
  value       = aws_ecs_task_definition.ecs_task_definition_mysql.arn
}

output "task_definition_family_bankapp" {
  description = "The family of the Task Definition."
  value       = aws_ecs_task_definition.ecs_task_definition.family
}

output "task_definition_revision_bankapp" {
  description = "The revision of the task in a particular family."
  value       = aws_ecs_task_definition.ecs_task_definition.revision
}

output "task_definition_family_mysql" {
  description = "The family of the Task Definition."
  value       = aws_ecs_task_definition.ecs_task_definition_mysql.family
}

output "task_definition_revision_mysql" {
  description = "The revision of the task in a particular family."
  value       = aws_ecs_task_definition.ecs_task_definition_mysql.revision
}

output "ecs_service_arn_bankapp" {
  description = "The ARN of the ECS service."
  value       = aws_ecs_service.ecs_service.arn
}

output "ecs_service_arn_mysql" {
  description = "The ARN of the ECS service."
  value       = aws_ecs_service.ecs_service_mysql.arn
}
