terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "web_app" {
  source = "../../modules/aws-web-app"

  name_prefix            = "prod-web-app"
  region                 = "us-east-1"
  ami_id                 = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_1.id
  associate_public_ip    = false
  ingress_cidr_ssh       = []
  ingress_cidr_http      = []
  tags                   = {
    Environment = "production"
  }
}

resource "aws_launch_template" "web_lt" {
  name_prefix   = "${module.web_app.name_prefix}-lt"
  image_id      = module.web_app.ami_id
  instance_type = module.web_app.instance_type

  vpc_security_group_ids = [module.web_app.security_group_id]

  network_interfaces {
    associate_public_ip_address = false
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      module.web_app.tags,
      {
        Name = "${module.web_app.name_prefix}-instance"
      }
    )
  }
}

# ... Create ALB, target group, listener, ASG similarly as before


######################
# NETWORKING RESOURCES #
######################

resource "aws_vpc" "prod" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "prod-vpc"
    Env  = "production"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "prod-igw"
  }
}

# Public subnets (for ALB)
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "prod-public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "prod-public-2"
  }
}

# Private subnets (for ASG instances)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "prod-private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "prod-private-2"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod-public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

##########################
# SECURITY GROUPS #
##########################

# SG for ALB - allow inbound HTTP from anywhere
resource "aws_security_group" "alb_sg" {
  name        = "prod-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prod-alb-sg"
  }
}

# SG for web ASG instances - allow inbound only from ALB SG on app port 80
resource "aws_security_group" "web_sg" {
  name        = "prod-web-sg"
  description = "Security group for web instances"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prod-web-sg"
  }
}

############################
# LOAD BALANCER & TARGET GROUP #
############################

resource "aws_lb" "alb" {
  name               = "prod-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "prod-alb"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "prod-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.prod.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
    protocol            = "HTTP"
  }

  tags = {
    Name = "prod-tg"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

###########################
# LAUNCH TEMPLATE (ASG) #
###########################

data "aws_ami" "amazon_linux" {
    most_recent      = true
    owners           = ["self"]
    filter {
        name   = "ami"
        values = ["ami-0c7217cdde317cfec"]
    }
}

####################
# AUTO SCALING GROUP #
####################

resource "aws_autoscaling_group" "web_asg" {
  name                      = "prod-web-asg"
  max_size                  = 4
  min_size                  = 2
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  target_group_arns         = [aws_lb_target_group.tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "prod-web-instance"
    propagate_at_launch = true
  }
}

################
# OUTPUTS #
################

output "alb_dns_name" {
  description = "DNS name of the public ALB"
  value       = aws_lb.alb.dns_name
}
