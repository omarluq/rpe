# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.vpc_name}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${var.vpc_name}-vpc-endpoints-sg"
    },
    var.tags
  )
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    [aws_route_table.private_az1.id],
    [aws_route_table.private_az2.id]
  )

  tags = merge(
    {
      Name = "${var.vpc_name}-s3-endpoint"
    },
    var.tags
  )
}

# SSM Interface Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = concat(
    aws_subnet.private_az1[*].id,
    aws_subnet.private_az2[*].id
  )

  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    {
      Name = "${var.vpc_name}-ssm-endpoint"
    },
    var.tags
  )
}

# SSM Messages Interface Endpoint
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = concat(
    aws_subnet.private_az1[*].id,
    aws_subnet.private_az2[*].id
  )

  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    {
      Name = "${var.vpc_name}-ssmmessages-endpoint"
    },
    var.tags
  )
}

# EC2 Messages Interface Endpoint (required for SSM)
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = concat(
    aws_subnet.private_az1[*].id,
    aws_subnet.private_az2[*].id
  )

  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    {
      Name = "${var.vpc_name}-ec2messages-endpoint"
    },
    var.tags
  )
}

# Data source for current region
data "aws_region" "current" {}
