variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "app_name" {
  description = "Application name"
  default     = "game-platform"
}

variable "db_username" {
  description = "Database administrator username"
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Secret key for JWT"
  type        = string
  sensitive   = true
}

variable "stripe_secret_key" {
  description = "Stripe API secret key"
  type        = string
  sensitive   = true
}

variable "stripe_webhook_secret" {
  description = "Stripe webhook secret"
  type        = string
  sensitive   = true
}

variable "repository_url" {
  description = "URL of the Git repository to clone"
  default     = "https://github.com/yourusername/game-project.git"
}

variable "ec2_key_name" {
  description = "Name of EC2 key pair"
  default     = "game-platform-key"
}
