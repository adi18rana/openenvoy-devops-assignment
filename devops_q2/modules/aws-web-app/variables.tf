variable "name_prefix" {
  description = "Prefix for naming all resources"
  type        = string
  default     = "aws-web-app"
}

variable "region" {
  description = "AWS region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID to use for the EC2 instance"
  type        = string
  default     = "ami-0c7217cdde317cfec"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "Subnet ID where to deploy the EC2 instance"
  type        = string
  default     = "subnet-12345abcdef"
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP with the instance"
  type        = bool
  default     = false
}

variable "ingress_cidr_ssh" {
  description = "CIDR blocks allowed to SSH to the instance"
  type        = list(string)
  default     = []
}

variable "ingress_cidr_http" {
  description = "CIDR blocks allowed to access the instance on HTTP port"
  type        = list(string)
  default     = ["35.136.814.675"]
}

variable "tags" {
  description = "Additional tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "vpc id"
  default = "vpc-12345678"
}