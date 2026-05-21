terraform {
  # Note: Run `aws s3 mb s3://kush-minecraft-backups` in your terminal 
  # BEFORE running terraform init so this backend works!
  backend "s3" {
    bucket = "kush-minecraft-backups"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
  
  # Added http provider to fetch your IP automatically
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" { default = true }

# Fetches your Mac's current IP address
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_security_group" "minecraft_sg" {
  name        = "minecraft-sg"
  description = "Minimalist SG for Minecraft server"

  # Admin Access: Restricted to your IP to meet Ops 4 rubric
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  # Public Access: Justified for Minecraft Java Edition clients
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Justified for system updates and ECR/S3 communication
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "mc_server" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = "LabInstanceProfile" # Required for S3/ECR access
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]

  tags = { Name = "Minecraft-k3s-Automated" }

  # Replaced Ansible provisioner with k3s automated bootstrap
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              curl -sfL https://get.k3s.io | sh -
              
              mkdir -p /home/ubuntu/.kube
              cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
              chown -R ubuntu:ubuntu /home/ubuntu/.kube
              EOF
}

output "server_ip" {
  description = "The public IP of the Minecraft server for client connection."
  value       = aws_instance.mc_server.public_ip
}