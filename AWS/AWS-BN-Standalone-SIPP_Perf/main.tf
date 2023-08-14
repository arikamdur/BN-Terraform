terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

data "aws_availability_zones" "azs" {
  state = "available"
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "bn_version" {
  most_recent = true
  owners      = ["752666320341"]
  filter {
    name   = "name"
    values = ["dialogic-bordernet-${var.bn_version}-*"]
  }
}


# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "BN-VPC"
  }
}

resource "aws_iam_instance_profile" "ec2_iam_instance_profile" {
  role = aws_iam_role.bn_sa_role.name
}

resource "aws_iam_role" "bn_sa_role" {
  name = "bn_sa_role"

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

resource "aws_iam_role_policy" "bn_policy" {
  name = "bn-policy"
  role = aws_iam_role.bn_sa_role.id

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
# Creating Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "BN-IGW"
  }
}

# Public Route Table

resource "aws_default_route_table" "rt" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "BN-RT"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  cidr_block              = var.public_subnet
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.azs.names[0]

  tags = {
    Name = "BN-Public-Subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  cidr_block        = var.private_subnet
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.azs.names[0]

  tags = {
    Name = "BN-Private-Subnet"
  }
}

# MGMT Subnet
resource "aws_subnet" "mgmt_subnet" {
  cidr_block        = var.mgmt_subnet
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.azs.names[0]

  tags = {
    Name = "BN-MGMT-Subnet"
  }
}


resource "aws_default_security_group" "bn_sg" {
  vpc_id = aws_vpc.main.id

  ingress = [
    {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },

    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = "outbound"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    Name = "BN-SG"
  }
}



resource "aws_security_group_rule" "bn_sg_allow_tcp" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_default_security_group.bn_sg.id
  source_security_group_id = aws_default_security_group.bn_sg.id
}

resource "aws_network_interface" "mgmt_int" {
  for_each            = toset(var.bn_vm_names)
  subnet_id       = aws_subnet.mgmt_subnet.id
  security_groups = [aws_default_security_group.bn_sg.id]
}

resource "aws_network_interface" "public_int" {
  for_each            = toset(var.bn_vm_names)
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_default_security_group.bn_sg.id]
}

resource "aws_network_interface" "private_int" {
  for_each            = toset(var.bn_vm_names)
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = [aws_default_security_group.bn_sg.id]
}

resource "aws_network_interface" "sipp_public_int" {
  for_each            = toset(var.sipp_vm_names)
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_default_security_group.bn_sg.id]
}

resource "aws_network_interface" "sipp_private_int" {
  for_each            = toset(var.sipp_vm_names)
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = [aws_default_security_group.bn_sg.id]
}

resource "aws_eip" "bn_eip_assign" {
  for_each            = toset(var.bn_vm_names)
  network_interface = aws_network_interface.mgmt_int[each.key].id
  vpc               = true
}

resource "aws_eip" "sipp_eip_assign" {
  for_each            = toset(var.sipp_vm_names)
  network_interface = aws_network_interface.sipp_public_int[each.key].id
  vpc               = true
}

resource "aws_instance" "bn1" {
  for_each            = toset(var.bn_vm_names)
  ami                  = "ami-0e75737b73123fe55"
  instance_type        = var.bn_instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_iam_instance_profile.name
  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.mgmt_int[each.key].id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 1
    network_interface_id  = aws_network_interface.public_int[each.key].id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 2
    network_interface_id  = aws_network_interface.private_int[each.key].id
    delete_on_termination = false
  }
  tags = {
    Name = "Enghouse BorderNet SBC"
  }
}

resource "aws_instance" "sipp" {
  for_each            = toset(var.sipp_vm_names)
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.sipp_instance_type
  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.sipp_public_int[each.key].id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 1
    network_interface_id  = aws_network_interface.sipp_private_int[each.key].id
    delete_on_termination = false
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo su
              yum install -y cmake gcc gcc-c++ ncurses ncurses-devel openssl libnet libpcap libpcap-devel gsl gsl-devel 
              sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
              sudo service sshd restart
              echo "ec2-user:sipp123" | chpasswd
              cd /root
              wget https://github.com/SIPp/sipp/releases/download/v3.6.1/sipp-3.6.1.tar.gz
              tar -xzvf sipp-3.6.1.tar.gz
              cd sipp-3.6.1
              ./build.sh --full
              echo PATH=$PATH:/root/sipp-3.6.1/ >> /etc/profile
            EOF   

  tags = {
    Name = "SIPP"
  }
}

output "BN_IPs" {
  value = { for k, v in aws_eip.bn_eip_assign : k => v.public_ip }
}

output "SIPP_IPs" {
  value = { for k, v in aws_eip.sipp_eip_assign : k => v.public_ip }
}

output "BN_Private_IPs" {
  value = { for k, v in aws_network_interface.private_int : k => v.private_ip }
}

output "BN_Public_IPs" {
  value = { for k, v in aws_network_interface.public_int : k => v.private_ip }
}