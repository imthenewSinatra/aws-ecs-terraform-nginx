output "application_url" {
  description = "Click to access the Nginx server"
  value       = "http://${aws_instance.ecs_node.public_ip}"
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.nginx_repo.repository_url
}