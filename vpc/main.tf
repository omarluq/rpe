# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    {
      Name = var.vpc_name
    },
    var.tags
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.vpc_name}-igw"
    },
    var.tags
  )
}

# Public Subnets - AZ1
resource "aws_subnet" "public_az1" {
  count             = length(var.public_subnet_cidrs_az1)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs_az1[count.index]
  availability_zone = var.availability_zones[0]

  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${var.vpc_name}-public-${var.availability_zones[0]}-${count.index + 1}"
      Type = "Public"
      AZ   = var.availability_zones[0]
    },
    var.tags
  )
}

# Public Subnets - AZ2
resource "aws_subnet" "public_az2" {
  count             = length(var.public_subnet_cidrs_az2)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs_az2[count.index]
  availability_zone = var.availability_zones[1]

  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${var.vpc_name}-public-${var.availability_zones[1]}-${count.index + 1}"
      Type = "Public"
      AZ   = var.availability_zones[1]
    },
    var.tags
  )
}

# Private Subnets - AZ1
resource "aws_subnet" "private_az1" {
  count             = length(var.private_subnet_cidrs_az1)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs_az1[count.index]
  availability_zone = var.availability_zones[0]

  tags = merge(
    {
      Name = "${var.vpc_name}-private-${var.availability_zones[0]}-${count.index + 1}"
      Type = "Private"
      AZ   = var.availability_zones[0]
    },
    var.tags
  )
}

# Private Subnets - AZ2
resource "aws_subnet" "private_az2" {
  count             = length(var.private_subnet_cidrs_az2)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs_az2[count.index]
  availability_zone = var.availability_zones[1]

  tags = merge(
    {
      Name = "${var.vpc_name}-private-${var.availability_zones[1]}-${count.index + 1}"
      Type = "Private"
      AZ   = var.availability_zones[1]
    },
    var.tags
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_az1" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(
    {
      Name = "${var.vpc_name}-nat-eip-${var.availability_zones[0]}"
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "nat_az2" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(
    {
      Name = "${var.vpc_name}-nat-eip-${var.availability_zones[1]}"
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways
resource "aws_nat_gateway" "az1" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat_az1[0].id
  subnet_id     = aws_subnet.public_az1[0].id

  tags = merge(
    {
      Name = "${var.vpc_name}-nat-${var.availability_zones[0]}"
      AZ   = var.availability_zones[0]
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "az2" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat_az2[0].id
  subnet_id     = aws_subnet.public_az2[0].id

  tags = merge(
    {
      Name = "${var.vpc_name}-nat-${var.availability_zones[1]}"
      AZ   = var.availability_zones[1]
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    {
      Name = "${var.vpc_name}-public-rt"
      Type = "Public"
    },
    var.tags
  )
}

# Private Route Table - AZ1
resource "aws_route_table" "private_az1" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.vpc_name}-private-rt-${var.availability_zones[0]}"
      Type = "Private"
      AZ   = var.availability_zones[0]
    },
    var.tags
  )
}

# Private Route Table - AZ2
resource "aws_route_table" "private_az2" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.vpc_name}-private-rt-${var.availability_zones[1]}"
      Type = "Private"
      AZ   = var.availability_zones[1]
    },
    var.tags
  )
}

# NAT Gateway Routes for Private Route Tables
resource "aws_route" "private_nat_az1" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private_az1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.az1[0].id
}

resource "aws_route" "private_nat_az2" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private_az2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.az2[0].id
}

# Route Table Associations - Public Subnets AZ1
resource "aws_route_table_association" "public_az1" {
  count          = length(var.public_subnet_cidrs_az1)
  subnet_id      = aws_subnet.public_az1[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Public Subnets AZ2
resource "aws_route_table_association" "public_az2" {
  count          = length(var.public_subnet_cidrs_az2)
  subnet_id      = aws_subnet.public_az2[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private Subnets AZ1
resource "aws_route_table_association" "private_az1" {
  count          = length(var.private_subnet_cidrs_az1)
  subnet_id      = aws_subnet.private_az1[count.index].id
  route_table_id = aws_route_table.private_az1.id
}

# Route Table Associations - Private Subnets AZ2
resource "aws_route_table_association" "private_az2" {
  count          = length(var.private_subnet_cidrs_az2)
  subnet_id      = aws_subnet.private_az2[count.index].id
  route_table_id = aws_route_table.private_az2.id
}
