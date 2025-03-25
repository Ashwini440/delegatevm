provider "aws" {
  region = "us-east-1"
}

# Generate SSH key pair
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "private_key" {
  filename        = "${path.module}/my-key.pem"
  content         = tls_private_key.my_key.private_key_pem
  file_permission = "0600"
}

# Store public key in AWS
resource "aws_key_pair" "my_key" {
  key_name   = "my-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

# Security Group for VM
resource "aws_security_group" "vm_sg" {
  name        = "vm-security-group"
  description = "Allow SSH and HTTP traffic"

  # Allow SSH from anywhere (Restrict to your IP in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
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
  key_name             = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [aws_security_group.vm_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y unzip wget
    wget -O delegate.tar.gz "https://app.harness.io/storage/harness-download/delegate/delegate.tar.gz"
    mkdir /opt/harness-delegate
    tar -xzf delegate.tar.gz -C /opt/harness-delegate
    cd /opt/harness-delegate
    chmod +x start.sh
    nohup ./start.sh &
  EOF

  tags = {
    Name = "delegate"
  }
}

# Terraform Outputs
output "instance_public_ip" {
  value = aws_instance.my_instance.public_ip
}

output "ssh_command" {
  value = "ssh -i my-key.pem ec2-user@${aws_instance.my_instance.public_ip}"
}
