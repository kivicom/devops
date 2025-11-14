resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = var.vpc_name }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.vpc_name}-igw" }
}

resource "aws_subnet" "public" {
  for_each = {
    for idx, cidr in var.public_subnets : idx => {
      cidr = cidr
      az   = var.availability_zones[idx]
    }
  }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = { Name = "${var.vpc_name}-public-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each = {
    for idx, cidr in var.private_subnets : idx => {
      cidr = cidr
      az   = var.availability_zones[idx]
    }
  }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = { Name = "${var.vpc_name}-private-${each.key}" }
}

resource "aws_eip" "nat" {
  count      = var.single_nat_gateway ? 1 : length(var.public_subnets)
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
  tags       = { Name = "${var.vpc_name}-nat-eip-${count.index}" }
}

resource "aws_nat_gateway" "nat" {
  count         = var.single_nat_gateway ? 1 : length(var.public_subnets)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(values(aws_subnet.public)[*].id, var.single_nat_gateway ? 0 : count.index)
  tags          = { Name = "${var.vpc_name}-nat-${count.index}" }
}
