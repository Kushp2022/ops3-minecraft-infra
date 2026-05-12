terraform {
  backend "s3" {
    bucket = "kush-minecraft-backups"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" { default = true }

resource "aws_security_group" "minecraft_sg" {
  name        = "minecraft-sg"
  description = "Minimalist SG for Minecraft server"

  # Admin Access: Justified for remote configuration via Ansible
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  tags = { Name = "Minecraft-Automated" }

  provisioner "local-exec" {
    # Wait for SSH to become ready, then trigger configuration
    command = "sleep 60 && export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i '${self.public_ip},' -u ubuntu --private-key ./labsuser.pem playbook.yml"
  }
}

output "server_ip" {
  description = "The public IP of the Minecraft server for client connection."
  value       = aws_instance.mc_server.public_ip
}