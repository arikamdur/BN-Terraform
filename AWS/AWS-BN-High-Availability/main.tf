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
  region = "us-east-1"
}

data "aws_availability_zones" "azs" {
  state = "available"
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
  role = aws_iam_role.bn_ha_role.name
}

resource "aws_iam_role" "bn_ha_role" {
  name = "bn_ha_role"

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
  role = aws_iam_role.bn_ha_role.id

  policy = jsonencode({
    Statement = [
      {
        Action = [
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
          "ec2:DescribeInstances",
          "iam:ListRoles"


        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
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

resource "aws_network_interface" "mgmt1_int" {
  private_ips_count = "1"
  subnet_id         = aws_subnet.mgmt_subnet.id
  security_groups   = [aws_default_security_group.bn_sg.id]
}

resource "aws_network_interface" "public1_int" {
  private_ips_count = "1"
  subnet_id         = aws_subnet.public_subnet.id
  security_groups   = [aws_default_security_group.bn_sg.id]
}

resource "aws_network_interface" "private1_int" {
  private_ips_count = "1"
  subnet_id         = aws_subnet.private_subnet.id
  security_groups   = [aws_default_security_group.bn_sg.id]
}

resource "aws_network_interface" "mgmt2_int" {
  subnet_id       = aws_subnet.mgmt_subnet.id
  security_groups = [aws_default_security_group.bn_sg.id]
}

resource "aws_network_interface" "public2_int" {
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_default_security_group.bn_sg.id]
}

resource "aws_network_interface" "private2_int" {
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = [aws_default_security_group.bn_sg.id]
}

resource "aws_eip" "eip_utility1" {
  network_interface = aws_network_interface.mgmt1_int.id
  vpc               = true
  tags = {
    Name = "BN1 - Utility IP"
  }
}


resource "aws_eip" "eip_utility2" {
  network_interface = aws_network_interface.mgmt2_int.id
  vpc               = true
  tags = {
    Name = "BN2 - Utility IP"
  }
}

resource "aws_eip" "eip_vip" {
  network_interface         = aws_network_interface.mgmt1_int.id
  vpc                       = true
  associate_with_private_ip = element(tolist(aws_network_interface.mgmt1_int.private_ips), 0)
  tags = {
    Name = "BN - MGMT Floating IP"
  }
}

resource "aws_instance" "bn1" {
  ami                  = "ami-05862efd9a72abc78"
  instance_type        = var.bn_instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_iam_instance_profile.name
  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.mgmt1_int.id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 1
    network_interface_id  = aws_network_interface.public1_int.id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 2
    network_interface_id  = aws_network_interface.private1_int.id
    delete_on_termination = false
  }
  tags = {
    Name = "Enghouse BorderNet SBC - HA1"
  }
}

resource "aws_instance" "bn2" {
  ami                  = "ami-0e4b140dd1de759e4"
  instance_type        = var.bn_instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_iam_instance_profile.name
  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.mgmt2_int.id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 1
    network_interface_id  = aws_network_interface.public2_int.id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 2
    network_interface_id  = aws_network_interface.private2_int.id
    delete_on_termination = false
  }
  tags = {
    Name = "Enghouse BorderNet SBC - HA2"
  }
}

output "BN1_Public_Utility" {
  description = "Contains the public IP address"
  value       = "https://${aws_eip.eip_utility1.public_ip}/"
}

output "BN2_Public_Utility" {
  description = "Contains the public IP address"
  value       = "https://${aws_eip.eip_utility2.public_ip}/"
}

output "MGMT_url" {
  value = "https://${aws_eip.eip_vip.public_ip}/"
}

output "BN1_Private_Utility" {
  description = "Contains the Private IP address of BN1"
  value       = aws_network_interface.mgmt1_int.private_ip
}

output "BN2_Private_Utility" {
  description = "Contains the Private IP address of BN2"
  value       = aws_network_interface.mgmt2_int.private_ip
}

