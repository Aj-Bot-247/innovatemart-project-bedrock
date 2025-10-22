# This file defines the network infrastructure for our EKS cluster.
# It creates a VPC, subnets, internet gateway, and route tables.

data "aws_availability_zones" "available" {}

resource "aws_vpc" "innovatemart_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "InnovateMart-VPC"
  }
}

# --- Public Subnets ---
resource "aws_internet_gateway" "innovatemart_igw" {
  vpc_id = aws_vpc.innovatemart_vpc.id
  tags = {
    Name = "InnovateMart-IGW"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.innovatemart_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.innovatemart_igw.id
  }
  tags = {
    Name = "InnovateMart-Public-RT"
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.innovatemart_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                = "InnovateMart-Public-Subnet-${count.index + 1}"
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}


# --- Private Subnets & NAT Gateway ---
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "InnovateMart-NAT-EIP"
  }
}

resource "aws_nat_gateway" "innovatemart_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id # Place NAT in the first public subnet
  tags = {
    Name = "InnovateMart-NAT-GW"
  }
  depends_on = [aws_internet_gateway.innovatemart_igw]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.innovatemart_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.innovatemart_nat.id
  }
  tags = {
    Name = "InnovateMart-Private-RT"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.innovatemart_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                = "InnovateMart-Private-Subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb"   = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}