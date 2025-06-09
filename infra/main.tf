provider "aws" {
  region = var.region
}

# VPC and Network Setup
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"

  tags = {
    Name = "${var.app_name}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"

  tags = {
    Name = "${var.app_name}-private-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.app_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "web" {
  name        = "${var.app_name}-web-sg"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-web-sg"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.app_name}-db-sg"
  description = "Allow database traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-db-sg"
  }
}

# S3 for Frontend
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.app_name}-frontend"

  tags = {
    Name = "${var.app_name}-frontend"
  }
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "frontend" {
  depends_on = [
    aws_s3_bucket_ownership_controls.frontend,
    aws_s3_bucket_public_access_block.frontend,
  ]

  bucket = aws_s3_bucket.frontend.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "frontend" {
  depends_on = [aws_s3_bucket_acl.frontend]

  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Principal = "*"
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      },
    ]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.frontend.website_endpoint
    origin_id   = "S3Origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # SPA routing - handle routes by serving index.html
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.app_name}-cloudfront"
  }
}

# RDS PostgreSQL Database
resource "aws_db_subnet_group" "default" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.public.id]

  tags = {
    Name = "${var.app_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.app_name}-db"
  engine                 = "postgres"
  engine_version         = "13.7"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "gameplatform"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = true
  skip_final_snapshot    = true

  tags = {
    Name = "${var.app_name}-db"
  }
}

# EC2 Instance for Backend
# Create user-data template from file
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    repository_url      = var.repository_url
    db_username         = var.db_username
    db_password         = var.db_password
    db_endpoint         = aws_db_instance.postgres.endpoint
    jwt_secret          = var.jwt_secret
    stripe_secret_key   = var.stripe_secret_key
    stripe_webhook_secret = var.stripe_webhook_secret
    cloudfront_domain   = aws_cloudfront_distribution.frontend.domain_name
  }
}

resource "aws_instance" "backend" {
  ami                    = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI - update for your region
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.ec2_key_name
  user_data              = data.template_file.user_data.rendered

  tags = {
    Name = "${var.app_name}-backend"
  }

  depends_on = [aws_db_instance.postgres]
}

# SSM Parameter Store for storing frontend build info
resource "aws_ssm_parameter" "api_url" {
  name  = "/${var.app_name}/api_url"
  type  = "String"
  value = "http://${aws_instance.backend.public_ip}:3000/api"
}

# Optional: CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "${var.app_name}-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EC2 CPU utilization"

  dimensions = {
    InstanceId = aws_instance.backend.id
  }
}

resource "aws_cloudwatch_event_rule" "ec2_shutdown" {
    name                = "ShutdownEC2Instance"
    description         = "Shut down EC2 instance during non-work hours"
    schedule_expression = "cron(0 0 * * ? *)"  # Midnight UTC
  }

  resource "aws_cloudwatch_event_target" "ec2_shutdown_target" {
    rule      = aws_cloudwatch_event_rule.ec2_shutdown.name
    target_id = "ShutdownInstance"
    arn       = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:automation-definition/AWS-StopEC2Instance"

    input = jsonencode({
      InstanceId = [aws_instance.backend.id]
    })
  }
