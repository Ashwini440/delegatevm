terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    tls = {                          # ✅ Add this to fix the error
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "local" {}

provider "tls" {}  # ✅ Ensure the local provider is defined




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
    set -e  # Exit script on error
    exec > /var/log/user-data.log 2>&1  # Log output for debugging

    # Install required packages
    sudo yum update -y || sudo apt update -y
    sudo yum install -y wget unzip || sudo apt install -y wget unzip

    # Download and Install Harness Delegate
    cd /opt
    curl -o delegate.tar.gz "https://app.harness.io/storage/harness-download/delegate/delegate.tar.gz"

    mkdir -p /opt/harness-delegate
    tar -xzf delegate.tar.gz -C /opt/harness-delegate

    # Set permissions and start the delegate
    cd /opt/harness-delegate
    chmod +x start.sh
    nohup ./start.sh > delegate.log 2>&1 &

    # Create a systemd service for auto-restart
    cat <<EOT > /etc/systemd/system/harness-delegate.service
    [Unit]
    Description=Harness Delegate
    After=network.target

    [Service]
    Type=simple
    User=root
    WorkingDirectory=/opt/harness-delegate
    ExecStart=/opt/harness-delegate/start.sh
    Restart=always

    [Install]
    WantedBy=multi-user.target
    EOT

    # Reload systemd and enable the delegate service
    systemctl daemon-reload
    systemctl enable harness-delegate
    systemctl start harness-delegate

EOF


  tags = {
    Name = "delegate"
  }
}

# SSH Command Output
output "ssh_command" {
  value = "ssh -i C:\\Users\\hr378\\Downloads\\cluster.pem ec2-user@${aws_instance.my_instance.public_ip}"
}
