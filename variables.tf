variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "The AWS region to deploy resources into."
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance size optimized for Minecraft Java edition."
}

variable "ami_id" {
  type        = string
  default     = "ami-053b0d53c279acc90"
  description = "Ubuntu 22.04 AMI ID for us-east-1."
}

variable "key_name" {
  type        = string
  default     = "vockey"
  description = "The name of the SSH key pair created in the AWS console."
}

variable "bucket_name" {
  type        = string
  default     = "kush-minecraft-backups"
  description = "The S3 bucket for remote state and world backups."
}