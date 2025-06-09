output "frontend_url" {
  description = "URL for the frontend application"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "backend_url" {
  description = "URL for the backend API"
  value       = "http://${aws_instance.backend.public_ip}:3000"
}

output "database_endpoint" {
  description = "Endpoint for the PostgreSQL database"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "ec2_instance_ip" {
  description = "Public IP address of the backend EC2 instance"
  value       = aws_instance.backend.public_ip
}
