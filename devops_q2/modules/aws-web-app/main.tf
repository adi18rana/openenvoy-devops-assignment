terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_security_group" "web_sg" {
  name        = "${var.name_prefix}-sg"
  description = "Web app security group"
  vpc_id      = var.vpc_id
  
  dynamic "ingress" {
    for_each = var.ingress_cidr_ssh
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_http
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-sg"
    }
  )
}

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  associate_public_ip_address = var.associate_public_ip
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-instance"
    }
  )
}
