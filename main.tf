terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "LUIT VPC"
  }
}

# Create Web Public Subnet
resource "aws_subnet" "web-subnet-1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Web-1a"
  }
}

resource "aws_subnet" "web-subnet-2" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Web-1b"
  }
}

# Create Database Private Subnet
resource "aws_subnet" "database-subnet-1" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Database 1"
  }
}

resource "aws_subnet" "database-subnet-2" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Database 2"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_subnet_group_name = aws_db_subnet_group.default.id
  engine               = "mysql"
  engine_version       = "8.0.28"
  instance_class       = "db.t2.micro"
  multi_az             = false
  name                 = "LUDB"
  username             = "admin"
  password             = "password"
  skip_final_snapshot  = true
}

resource "aws_db_subnet_group" "default" {
  name       = "luit"
  subnet_ids = [aws_subnet.database-subnet-1.id, aws_subnet.database-subnet-2.id]

  tags = {
    Name = "RDS subnet group"
  }
}

