output "vpc_id" { value = aws_vpc.main.id }
output "public_subnet_id" { value = aws_subnet.public.id }
output "ec2_instance_public_ips" { value = [for i in aws_instance.target : i.public_ip] }
output "ec2_instance_ids" { value = [for i in aws_instance.target : i.id] }
output "ecr_repository_url" { value = aws_ecr_repository.web.repository_url }
output "ecs_cluster_name" { value = aws_ecs_cluster.main.name }
output "ecs_service_name" { value = aws_ecs_service.web.name }
output "ecs_task_definition" { value = aws_ecs_task_definition.web.arn }
output "created_key_pair_private_key_pem" {
  value = tls_private_key.key.*.private_key_pem
  description = "Private key PEM for the created key pair (present if create_key_pair=true and ssh_key_name empty)."
  sensitive = true
}