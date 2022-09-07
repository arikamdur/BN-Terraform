terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63.0"
    }
  }
  required_version = "~> 1.0.0"
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

data "aws_availability_zones" "azs" {
  state = "available"
}

data "aws_ami" "bn_version" {
  most_recent = true
  owners      = ["752666320341"]
  filter {
    name   = "name"
    values = ["dialogic-bordernet-${var.bn_version}-170*"]
  }
}


resource "aws_iam_instance_profile" "ec2_iam_instance_profile" {
  role = aws_iam_role.bn_sa_role01.name
}

resource "aws_iam_role" "bn_sa_role01" {
  name = "bn_sa_role01"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      },
    ]
  })
}

resource "aws_iam_role_policy" "bn_policy01" {
  name = "bn_policy01"
  role = aws_iam_role.bn_sa_role01.id

  policy = jsonencode({
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# create interfaces

resource "aws_network_interface" "mgmt_int" {
  subnet_id       = var.mgmt_subnet_id
  security_groups = [var.mySG_id]
}

resource "aws_network_interface" "public_int" {
  subnet_id       = var.public_subnet_id
  security_groups = [var.mySG_id]
}

resource "aws_network_interface" "private_int" {
  subnet_id       = var.private_subnet_id
  security_groups = [var.mySG_id]
}

resource "aws_eip" "eip_assign" {
  network_interface = aws_network_interface.mgmt_int.id
  vpc               = true
}

# create bn vm

resource "aws_instance" "bn1" {
  ami                  = data.aws_ami.bn_version.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_iam_instance_profile.name
  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.mgmt_int.id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 1
    network_interface_id  = aws_network_interface.public_int.id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 2
    network_interface_id  = aws_network_interface.private_int.id
    delete_on_termination = false
  }
  tags = {
    Name = "Enghouse BorderNet SBC sameVPC"
  }
}


output "MGMT_url" {
  value = "https://${aws_eip.eip_assign.public_ip}/"
}