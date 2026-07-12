variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "your_ip" {
  description = "Your public IP, for restricting SSH access (format: x.x.x.x/32)"
  type        = string
}

variable "alert_email" {
  description = "Email for CloudWatch alarm notifications"
  type        = string
}

variable "key_pair_name" {
  description = "Name for the EC2 key pair"
  type        = string
  default     = "terraform-key"
}

variable "public_key_path" {
  description = "Path to your SSH public key file"
  type        = string
  default     = "./terraform-key.pub"
}

variable "public_key_content" {
  description = "SSH public key content (used in CI where no local file exists)"
  type        = string
  default     = ""
}