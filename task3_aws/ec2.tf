provider "aws" {
  access_key = var.aws_access_key # Your akey
  secret_key = var.aws_secret_key # Your skey  
  region     = var.region
}

resource "aws_instance" "Moodle_server" {
  ami                    = var.ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.moodle_sg.id]
  key_name               = aws_key_pair.moodlekey.key_name
  user_data              = file("moodle.sh")
  user_data_replace_on_change = true

  root_block_device {
    volume_size = "10"
    volume_type = "gp2"
  }
  tags = var.tags
}

resource "aws_key_pair" "moodlekey" {
  key_name   = "moodlekey"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "MOODLEKEY" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "moodlekey"
}

resource "aws_security_group" "moodle_sg" {
  name        = "MoodleSC"
  description = "MoodleSC Terraform"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Создание Elastic IP
resource "aws_eip" "moodle_eip" {
  instance = aws_instance.Moodle_server.id
}

output "instance_public_ip" {
  description = "Public_IP_EC2"
  value       = aws_instance.Moodle_server.public_ip
}

output "elastic_ip" {
  description = "Elastic_IP_EC2"
  value = aws_eip.moodle_eip.public_ip
}