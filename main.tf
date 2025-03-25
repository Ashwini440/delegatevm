terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {                          # ✅ Add this to fix the error
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "local" {}   # ✅ Ensure the local provider is defined

resource "local_file" "private_key" {
  filename        = "C:\\Users\\hr378\\Downloads\\cluster.pem"
  content         = "your_private_key_content_here"  # If dynamically generated, use `tls_private_key.my_key.private_key_pem`
  file_permission = "0600"
}


# Security Group for VM
resource "aws_security_group" "vm_sg" {
  name        = "vm-security-group"
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH (Change to your IP for security)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Provision EC2 instance
resource "aws_instance" "my_instance" {
  ami                  = "ami-03a6dea316143e1c8"  # Replace with a valid AMI ID
  instance_type        = "t2.micro"
  key_name             = "cluster"  # Use the existing key pair
  vpc_security_group_ids = [aws_security_group.vm_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    set -e
    sudo apt update -y
    sudo apt install -y unzip wget

    # Download and Install Harness Delegate
    wget -O /tmp/delegate.tar.gz "https://app.harness.io/storage/harness-download/delegate/delegate.tar.gz"
    mkdir -p /opt/harness-delegate
    tar -xzf /tmp/delegate.tar.gz -C /opt/harness-delegate
    cd /opt/harness-delegate
    chmod +x start.sh
    nohup ./start.sh > /opt/harness-delegate/delegate.log 2>&1 &
  EOF

  tags = {
    Name = "delegate"
  }
}

# SSH Command Output
output "ssh_command" {
  value = "ssh -i C:\\Users\\hr378\\Downloads\\cluster.pem ec2-user@${aws_instance.my_instance.public_ip}"
}
