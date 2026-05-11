provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" { default = true }

resource "aws_security_group" "minecraft_sg" {
  name = "minecraft-sg"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "mc_server" {
  ami                  = "ami-053b0d53c279acc90"
  instance_type        = "t3.medium"
  key_name             = "vockey"
  iam_instance_profile = "LabInstanceProfile"
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]

  tags = { Name = "Minecraft-Automated" }

  provisioner "local-exec" {
    command = "sleep 60 && export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i '${self.public_ip},' --private-key ./cs312-key.pem playbook.yml"
  }
}
-
output "server_ip" {
  value = aws_instance.mc_server.public_ip
}
