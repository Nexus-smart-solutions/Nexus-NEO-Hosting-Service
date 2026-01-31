# ===================================
# NETWORK MODULE - MAIN
# ===================================

locals {
  name_prefix = "${var.customer_domain}-${var.environment}"
  azs = length(var.availability_zones) > 0 ? var.availability_zones : [
    data.aws_availability_zones.available.names[0]
  ]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ===================================
# VPC
# ===================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-vpc"
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
      Name     = "${local.name_prefix}-igw"
      Customer = var.customer_domain
    }
  )
}

# ===================================
# PUBLIC SUBNETS
# ===================================

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index % length(local.azs)]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name     = "${local.name_prefix}-public-${count.index + 1}"
      Type     = "Public"
      Customer = var.customer_domain
    }
  )
}

# ===================================
# PRIVATE SUBNETS
# ===================================

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(
    var.tags,
    {
      Name     = "${local.name_prefix}-private-${count.index + 1}"
      Type     = "Private"
      Customer = var.customer_domain
    }
  )
}

# ===================================
# ROUTE TABLE - PUBLIC
# ===================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name     = "${local.name_prefix}-public-rt"
      Customer = var.customer_domain
    }
  )
}

resource "aws_route" "public_internet" {
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
# NAT GATEWAY (OPTIONAL)
# ===================================

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name     = "${local.name_prefix}-nat-eip"
      Customer = var.customer_domain
    }
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.tags,
    {
      Name     = "${local.name_prefix}-nat-gw"
      Customer = var.customer_domain
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ===================================
# ROUTE TABLE - PRIVATE
# ===================================

resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name     = "${local.name_prefix}-private-rt"
      Customer = var.customer_domain
    }
  )
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

resource "aws_route_table_association" "private" {
  count = var.enable_nat_gateway ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# ===================================
# VPC FLOW LOGS
# ===================================

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name              = "/aws/${local.name_prefix}/vpc-flow-logs"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Customer = var.customer_domain
    }
  )
}

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name = "${local.name_prefix}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, { Customer = var.customer_domain })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name = "${local.name_prefix}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "main" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.vpc_flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Customer = var.customer_domain
    }
  )
}
