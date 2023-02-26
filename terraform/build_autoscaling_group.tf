terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

variable "environ_tag" {
  default = "coder_autoscaling_group"
}

variable "ipv4_cidr_block" {
  default = "10.118.0.0/16"
}

variable "subnet_number" {
  default = "0"
}

resource "aws_vpc" "vpc" {
  cidr_block                       = var.ipv4_cidr_block
  assign_generated_ipv6_cidr_block = true

  tags = { Environment = var.environ_tag }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = { Environment = var.environ_tag }
}

resource "aws_subnet" "sub" {
  vpc_id          = aws_vpc.vpc.id
  cidr_block      = cidrsubnet(aws_vpc.vpc.cidr_block, 8, var.subnet_number)
  ipv6_cidr_block = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, var.subnet_number)

  map_public_ip_on_launch = true

  tags = { Environment = var.environ_tag }
}


resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = { Environment = var.environ_tag }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.sub.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_security_group" "allow_ssh_wireguard" {
  name        = "allow_ssh_wireguard"
  description = "Allow SSH and wireguard"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Wireguard from anywhere"
    from_port        = 51820
    to_port          = 51820
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "All Egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Environment = var.environ_tag }
}

resource "aws_key_pair" "key" {
  key_name   = "key"
  public_key = file("key.pub")

  tags = { Environment = var.environ_tag }
}

resource "aws_launch_template" "coder_node" {
  name_prefix   = "coder_"
  image_id      = "ami-05279711430507566"
  instance_type = "t3a.large"

  network_interfaces {
    ipv6_address_count = 1
    subnet_id          = aws_subnet.sub.id
    security_groups    = [aws_security_group.allow_ssh_wireguard.id]
  }

  key_name = aws_key_pair.key.key_name

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs { volume_size = 10 }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Environment = var.environ_tag }
  }

}

resource "aws_autoscaling_group" "coder_nodes" {
  name     = "coder_nodes"
  max_size = 10
  min_size = 0

  launch_template {
    id      = aws_launch_template.coder_node.id
    version = "$Latest"
  }

  tag {
    key                 = "Environment"
    value               = var.environ_tag
    propagate_at_launch = true
  }
}