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
  region = var.region1
  alias  = "region1"
}

provider "aws" {
  region = var.region2
  alias  = "region2"
}

data "aws_ami" "latest-amazon-linux-image" {
  provider    = aws.region1
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "bn_version_region1" {
  provider    = aws.region1
  most_recent = true
  owners      = ["752666320341"]
  filter {
    name   = "name"
    values = ["dialogic-bordernet-${var.bn_version}-*"]
  }
}

data "aws_ami" "bn_version_region2" {
  provider    = aws.region2
  most_recent = true
  owners      = ["752666320341"]
  filter {
    name   = "name"
    values = ["dialogic-bordernet-${var.bn_version}-*"]
  }
}

data "aws_availability_zones" "region1_az" {
  provider = aws.region1

  state = "available"
}

data "aws_availability_zones" "region2_az" {
  provider = aws.region2

  state = "available"
}


# Create a VPC
resource "aws_vpc" "region1_vpc" {
  provider   = aws.region1
  cidr_block = var.region1_vpc_cidr
  tags = {
    Name = "Region1-BN-VPC"
  }
}

resource "aws_vpc" "region2_vpc" {
  provider   = aws.region2
  cidr_block = var.region2_vpc_cidr
  tags = {
    Name = "Region2-BN-VPC"
  }
}


resource "aws_iam_instance_profile" "region1_ec2_iam_instance_profile" {
  provider = aws.region1
  role     = aws_iam_role.region1_bn_sa_role.name
}

resource "aws_iam_instance_profile" "region2_ec2_iam_instance_profile" {
  provider = aws.region2
  role     = aws_iam_role.region2_bn_sa_role.name
}

resource "aws_iam_role" "region1_bn_sa_role" {
  provider = aws.region1
  name     = "region1_bn_sa_role"

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

resource "aws_iam_role" "region2_bn_sa_role" {
  provider = aws.region2
  name     = "region2_bn_sa_role"

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

resource "aws_iam_role_policy" "region1_bn_policy" {
  provider = aws.region1
  name     = "region1_bn-policy"
  role     = aws_iam_role.region1_bn_sa_role.id

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

resource "aws_iam_role_policy" "region2_bn_policy" {
  provider = aws.region2
  name     = "region2_bn-policy"
  role     = aws_iam_role.region1_bn_sa_role.id

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

resource "aws_internet_gateway" "region1_igw" {
  provider = aws.region1
  vpc_id   = aws_vpc.region1_vpc.id

  tags = {
    Name = "Region1-BN-IGW"
  }
}

resource "aws_internet_gateway" "region2_igw" {
  provider = aws.region2
  vpc_id   = aws_vpc.region2_vpc.id

  tags = {
    Name = "Region2-BN-IGW"
  }
}

# Public Route Table

resource "aws_default_route_table" "region1_rt" {
  provider               = aws.region1
  default_route_table_id = aws_vpc.region1_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.region1_igw.id
  }

  tags = {
    Name = "Region1-BN-RT"
  }
}

resource "aws_default_route_table" "region2_rt" {
  provider               = aws.region2
  default_route_table_id = aws_vpc.region2_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.region2_igw.id
  }

  tags = {
    Name = "Region2-BN-RT"
  }
}

# Public Subnet
resource "aws_subnet" "region1_public_subnet" {
  provider                = aws.region1
  cidr_block              = var.region1_public_subnet
  vpc_id                  = aws_vpc.region1_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.region1_az.names[0]

  tags = {
    Name = "Region1-BN-Public-Subnet"
  }
}

resource "aws_subnet" "region2_public_subnet" {
  provider                = aws.region2
  cidr_block              = var.region2_public_subnet
  vpc_id                  = aws_vpc.region2_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.region2_az.names[0]

  tags = {
    Name = "Region2-BN-Public-Subnet"
  }
}

# Private Subnet
resource "aws_subnet" "region1_private_subnet" {
  provider          = aws.region1
  cidr_block        = var.region1_private_subnet
  vpc_id            = aws_vpc.region1_vpc.id
  availability_zone = data.aws_availability_zones.region1_az.names[0]

  tags = {
    Name = "Region1-BN-Private-Subnet"
  }
}

resource "aws_subnet" "region2_private_subnet" {
  provider          = aws.region2
  cidr_block        = var.region2_private_subnet
  vpc_id            = aws_vpc.region2_vpc.id
  availability_zone = data.aws_availability_zones.region2_az.names[0]

  tags = {
    Name = "Region2-BN-Private-Subnet"
  }
}

# MGMT Subnet
resource "aws_subnet" "region1_mgmt_subnet" {
  provider          = aws.region1
  cidr_block        = var.region1_mgmt_subnet
  vpc_id            = aws_vpc.region1_vpc.id
  availability_zone = data.aws_availability_zones.region1_az.names[0]

  tags = {
    Name = "Region1-BN-MGMT-Subnet"
  }
}

resource "aws_subnet" "region2_mgmt_subnet" {
  provider          = aws.region2
  cidr_block        = var.region2_mgmt_subnet
  vpc_id            = aws_vpc.region2_vpc.id
  availability_zone = data.aws_availability_zones.region2_az.names[0]

  tags = {
    Name = "Region2-BN-MGMT-Subnet"
  }
}


resource "aws_default_security_group" "region1_bn_sg" {
  provider = aws.region1
  vpc_id   = aws_vpc.region1_vpc.id

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
    },
        {
      description      = "Allow VPC Peering"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = [var.region1_vpc_cidr,var.region2_vpc_cidr]
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
    Name = "Region1-BN-SG"
  }
}

resource "aws_default_security_group" "region2_bn_sg" {
  provider = aws.region2
  vpc_id   = aws_vpc.region2_vpc.id

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
    },
    {
      description      = "Allow VPC Peering"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = [var.region1_vpc_cidr,var.region2_vpc_cidr]
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
    Name = "Region2-BN-SG"
  }
}



resource "aws_network_interface" "region1_mgmt_int" {
  provider        = aws.region1
  subnet_id       = aws_subnet.region1_mgmt_subnet.id
  security_groups = [aws_default_security_group.region1_bn_sg.id]
}

resource "aws_network_interface" "region2_mgmt_int" {
  provider        = aws.region2
  subnet_id       = aws_subnet.region2_mgmt_subnet.id
  security_groups = [aws_default_security_group.region2_bn_sg.id]
}

resource "aws_network_interface" "region1_public_int" {
  provider        = aws.region1
  subnet_id       = aws_subnet.region1_public_subnet.id
  security_groups = [aws_default_security_group.region1_bn_sg.id]
}

resource "aws_network_interface" "region2_public_int" {
  provider        = aws.region2
  subnet_id       = aws_subnet.region2_public_subnet.id
  security_groups = [aws_default_security_group.region2_bn_sg.id]
}

resource "aws_network_interface" "region1_private_int" {
  provider        = aws.region1
  subnet_id       = aws_subnet.region1_private_subnet.id
  security_groups = [aws_default_security_group.region1_bn_sg.id]
}

resource "aws_network_interface" "region2_private_int" {
  provider        = aws.region2
  subnet_id       = aws_subnet.region2_private_subnet.id
  security_groups = [aws_default_security_group.region2_bn_sg.id]
}

resource "aws_network_interface" "region1_sipp_public_int" {
  provider        = aws.region1
  subnet_id       = aws_subnet.region1_public_subnet.id
  security_groups = [aws_default_security_group.region1_bn_sg.id]
}


resource "aws_network_interface" "region1_sipp_private_int" {
  provider        = aws.region1
  subnet_id       = aws_subnet.region1_private_subnet.id
  security_groups = [aws_default_security_group.region1_bn_sg.id]
}



resource "aws_eip" "region1_bn_eip_assign" {
  provider          = aws.region1
  network_interface = aws_network_interface.region1_mgmt_int.id
  vpc               = true
}

resource "aws_eip" "region2_bn_eip_assign" {
  provider          = aws.region2
  network_interface = aws_network_interface.region2_mgmt_int.id
  vpc               = true
}

resource "aws_eip" "region1_sipp_eip_assign" {
  provider          = aws.region1
  network_interface = aws_network_interface.region1_sipp_public_int.id
  vpc               = true
}

resource "aws_vpc_peering_connection" "region1_peering" {
  provider    = aws.region1
  peer_vpc_id = aws_vpc.region2_vpc.id
  peer_region = var.region2
  vpc_id      = aws_vpc.region1_vpc.id
}

resource "aws_vpc_peering_connection_accepter" "region2_peer_accept" {
  provider                  = aws.region2
  vpc_peering_connection_id = aws_vpc_peering_connection.region1_peering.id
  auto_accept               = true
}

resource "aws_route" "region1_pcx_route" {
  provider                  = aws.region1
  route_table_id            = aws_default_route_table.region1_rt.id
  destination_cidr_block    = var.region2_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.region1_peering.id
  depends_on                = [aws_default_route_table.region1_rt]
}

resource "aws_route" "region2_pcx_route" {
  provider                  = aws.region2
  route_table_id            = aws_default_route_table.region2_rt.id
  destination_cidr_block    = var.region1_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.region1_peering.id
  depends_on                = [aws_default_route_table.region2_rt]
}

resource "aws_instance" "region1_bn" {
  provider             = aws.region1
  ami                  = data.aws_ami.bn_version_region1.id
  instance_type        = var.bn_instance_type
  iam_instance_profile = aws_iam_instance_profile.region1_ec2_iam_instance_profile.name
  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.region1_mgmt_int.id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 1
    network_interface_id  = aws_network_interface.region1_public_int.id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 2
    network_interface_id  = aws_network_interface.region1_private_int.id
    delete_on_termination = false
  }
  tags = {
    Name = "Region1-Enghouse BorderNet SBC"
  }
}

resource "aws_instance" "region2_bn" {
  provider             = aws.region2
  ami                  = data.aws_ami.bn_version_region2.id
  instance_type        = var.bn_instance_type
  iam_instance_profile = aws_iam_instance_profile.region2_ec2_iam_instance_profile.name
  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.region2_mgmt_int.id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 1
    network_interface_id  = aws_network_interface.region2_public_int.id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 2
    network_interface_id  = aws_network_interface.region2_private_int.id
    delete_on_termination = false
  }
  tags = {
    Name = "Region2-Enghouse BorderNet SBC"
  }
}



resource "aws_instance" "sipp" {
  provider      = aws.region1
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = "t2.micro"
  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.region1_sipp_public_int.id
    delete_on_termination = false
  }
  network_interface {
    device_index          = 1
    network_interface_id  = aws_network_interface.region1_sipp_private_int.id
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
              ./build.sh --common
              echo PATH=$PATH:/root/sipp-3.6.1/ >> /etc/profile
            EOF   

  tags = {
    Name = "SIPP"
  }
}

output "REGION1_BN_MGMT_IP" {
  description = "Contains the public IP address"
  value       = "https://${aws_eip.region1_bn_eip_assign.public_ip}/"
}

output "REGION2_BN_MGMT_IP" {
  description = "Contains the public IP address"
  value       = "https://${aws_eip.region2_bn_eip_assign.public_ip}/"
}

output "REGION1_BN_Private_Utility" {
  description = "Contains the Private IP address of BN1"
  value       = aws_network_interface.region1_mgmt_int.private_ip
}

output "REGION2_BN_Private_Utility" {
  description = "Contains the Private IP address of BN2"
  value       = aws_network_interface.region2_mgmt_int.private_ip
}

output "SIPP_MGMT_IP" {
  description = "Contains the public IP address"
  value       = aws_eip.region1_sipp_eip_assign.public_ip
}