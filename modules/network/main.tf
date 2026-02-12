# ===================================
# VPC CONFIGURATION
# ===================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.customer_domain}-vpc"
      Customer    = var.customer_domain
      Environment = var.environment
    }
  )
}

# ===================================
# INTERNET GATEWAY
# ===================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.customer_domain}-igw"
      Customer    = var.customer_domain
      Environment = var.environment
    }
  )
}

# ===================================
# PUBLIC SUBNETS
# ===================================

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.customer_domain}-public-subnet-${count.index + 1}"
      Customer    = var.customer_domain
      Environment = var.environment
      Type        = "Public"
    }
  )
}

# ===================================
# PRIVATE SUBNETS
# ===================================

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name        = "${var.customer_domain}-private-subnet-${count.index + 1}"
      Customer    = var.customer_domain
      Environment = var.environment
      Type        = "Private"
    }
  )
}

# ===================================
# ELASTIC IP FOR NAT GATEWAY
# ===================================

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name        = "${var.customer_domain}-nat-eip"
      Customer    = var.customer_domain
      Environment = var.environment
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ===================================
# NAT GATEWAY
# ===================================

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.tags,
    {
      Name        = "${var.customer_domain}-nat-gateway"
      Customer    = var.customer_domain
      Environment = var.environment
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ===================================
# PUBLIC ROUTE TABLE
# ===================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.customer_domain}-public-rt"
      Customer    = var.customer_domain
      Environment = var.environment
      Type        = "Public"
    }
  )
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ===================================
# PRIVATE ROUTE TABLE
# ===================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.customer_domain}-private-rt"
      Customer    = var.customer_domain
      Environment = var.environment
      Type        = "Private"
    }
  )
}

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ===================================
# VPC FLOW LOGS (OPTIONAL)
# ===================================

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.customer_domain}"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name        = "${var.customer_domain}-vpc-flow-logs"
      Customer    = var.customer_domain
      Environment = var.environment
    }
  )
}

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix = "${var.customer_domain}-vpc-flow-logs-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix = "${var.customer_domain}-vpc-flow-logs-"
  role        = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.vpc_flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.customer_domain}-vpc-flow-log"
      Customer    = var.customer_domain
      Environment = var.environment
    }
  )
}

# ===================================
# VPC ENDPOINTS - S3 GATEWAY
# ===================================

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"

  route_table_ids = concat(
    [aws_route_table.public.id],
    [aws_route_table.private.id]
  )

  tags = merge(
    var.tags,
    {
      Name        = "${var.customer_domain}-s3-endpoint"
      Customer    = var.customer_domain
      Environment = var.environment
    }
  )
}
