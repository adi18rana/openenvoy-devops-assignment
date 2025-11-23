output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "security_group_id" {
  description = "Security Group ID attached to the instance"
  value       = aws_security_group.web_sg.id
}
