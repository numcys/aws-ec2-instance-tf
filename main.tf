terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  region = "ap-southeast-1"
  ami = "ami-0d07675d294f17973"
}

# Configure the AWS Provider
provider "aws" {
  region =  "${local.region}"
  profile = "local"
}


resource "aws_vpc" "this" {
  cidr_block = "10.20.20.0/25"
  tags = {
    "Name" = "app-1"
  }
}
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.20.20.64/26"
  availability_zone = "${local.region}a"
  tags = {
    "Name" = "app-1-public"
  }
}
resource "aws_route_table" "this-rt" {
  vpc_id = aws_vpc.this.id
  tags = {
    "Name" = "app-1-route-table"
  }
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.this-rt.id
}
resource "aws_internet_gateway" "this-igw" {
  vpc_id = aws_vpc.this.id
  tags = {
    "Name" = "app-1-gateway"
  }
}
resource "aws_route" "internet-route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.this-rt.id
  gateway_id             = aws_internet_gateway.this-igw.id
}

resource "aws_security_group" "web-pub-sg" {
  name        = "allow_inbound_access"
  description = "allow inbound traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "from library ip range"
    from_port   = "3389"
    to_port     = "3389"
    protocol    = "tcp"
    cidr_blocks = ["147.219.191.0/24"]
  }
  ingress {
    protocol = "tcp"
    from_port = 8080
    to_port = 8080
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    to_port     = "0"
  }
  tags = {
    "Name" = "app-1-ec2-sg"
  }
}

resource "aws_instance" "app-server" {
  instance_type               = "t2.micro"
  ami                         = local.ami
  vpc_security_group_ids      = [aws_security_group.web-pub-sg.id]
  subnet_id                   = aws_subnet.public.id
  key_name                    = "${local.region}"
  associate_public_ip_address = true
  user_data = file("user_data/user_data.tpl")
  tags = {
    Name = "Load-Test-Server"
  }
}

output "instance_ips" {
  value = aws_instance.app-server.public_ip
}
