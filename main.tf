data "aws_vpc" "existing" {
  id = "vpc-081d12cf7965deaca"
}

data "aws_availability_zones" "available" {}

# PUBLIC SUBNETS (2 AZ)
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = data.aws_vpc.existing.id
  cidr_block              = element(["192.168.10.0/24", "192.168.11.0/24"], count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "taxsutra-public-${count.index + 1}"
  }
}

# PRIVATE SUBNETS (2 AZ)
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = data.aws_vpc.existing.id
  cidr_block        = element(["192.168.20.0/24", "192.168.21.0/24"], count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "taxsutra-private-${count.index + 1}"
  }
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.existing.id
}

# NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.igw]
}

# ROUTES
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.existing.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = data.aws_vpc.existing.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# SG
resource "aws_security_group" "app_sg" {
  vpc_id = data.aws_vpc.existing.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }
}

# APP INSTANCES
resource "aws_instance" "app" {
  count         = 3
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  subnet_id = aws_subnet.private[count.index % 2].id

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "taxsutra-test-app-${count.index + 1}"
  }
}

# MEMCACHE
resource "aws_instance" "memcache" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  subnet_id = aws_subnet.private[0].id

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "taxsutra-test-memcache-01"
  }
}

# ES
resource "aws_instance" "es" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  subnet_id = aws_subnet.private[1].id

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "taxsutra-test-elasticsearch-01"
  }
}

# ALB
resource "aws_lb" "alb" {
  name               = "taxsutra-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.app_sg.id]
}

# TG
resource "aws_lb_target_group" "tg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.existing.id
}

# ATTACH
resource "aws_lb_target_group_attachment" "app_attach" {
  count            = 3
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.app[count.index].id
}

# LISTENER
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
