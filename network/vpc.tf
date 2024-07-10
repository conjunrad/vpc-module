data "aws_availability_zones" "avaliable" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_vpc" "main_vpc" {
  cidr_block = var.main_vpc_cidr
  tags = {
    Name  = "${var.general_tags["Environment"]}-vpc"
    Owner = "${var.general_tags["Owner"]}"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name  = "${var.general_tags["Environment"]}-igw"
    Owner = "${var.general_tags["Owner"]}"
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = element(var.public_subnet_cidr, count.index)
  availability_zone       = data.aws_availability_zones.avaliable.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name  = "${var.general_tags["Environment"]}-public-subnet-${count.index + 1}"
    Owner = "${var.general_tags["Owner"]}"
  }
}

resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name  = "${var.general_tags["Environment"]}-route-public-subnets"
    Owner = "${var.general_tags["Owner"]}"
  }
}

resource "aws_route_table_association" "public_subnets" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}

resource "aws_eip" "eip_nat_gw" {
  count  = length(var.private_subnet_cidr)
  domain = "vpc"

  tags = {
    Name  = "${var.general_tags["Environment"]}-eip-nat-gw-${count.index + 1}"
    Owner = "${var.general_tags["Owner"]}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.private_subnet_cidr)
  allocation_id = aws_eip.eip_nat_gw[count.index].id
  subnet_id     = element(aws_subnet.public_subnets[*].id, count.index)

  tags = {
    Name  = "${var.general_tags["Environment"]}-nat-gw-${count.index + 1}"
    Owner = "${var.general_tags["Owner"]}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidr)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = element(var.private_subnet_cidr, count.index)
  availability_zone = data.aws_availability_zones.avaliable.names[count.index]

  tags = {
    Name  = "${var.general_tags["Environment"]}-private-subnet-${count.index + 1}"
    Owner = "${var.general_tags["Owner"]}"
  }
}

resource "aws_route_table" "private_subnets" {
  count  = length(var.private_subnet_cidr)
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    Name  = "${var.general_tags["Environment"]}-route-private-subnet-${count.index + 1}"
    Owner = "${var.general_tags["Owner"]}"
  }
}

resource "aws_route_table_association" "private_routes" {
  count          = length(aws_subnet.private_subnets[*].id)
  route_table_id = aws_route_table.private_subnets[count.index].id
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
}
