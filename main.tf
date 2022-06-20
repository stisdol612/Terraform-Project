resource "aws_vpc" "lu_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "LUIT VPC"
  }
}


resource "aws_subnet" "web_subnet" {
  vpc_id                  = aws_vpc.lu_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Web Subnet"
  }
}

resource "aws_subnet" "app_subnet" {
  vpc_id                  = aws_vpc.lu_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "App Subnet"
  }
}

resource "aws_subnet" "database_subnet" {
  vpc_id            = aws_vpc.lu_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Database 1"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lu_vpc.id

  tags = {
    Name = "LU-IGW"
  }
}

resource "aws_route_table" "web_rt" {
  vpc_id = aws_vpc.lu_vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "RT for Subnet"
  }
}

resource "aws_route_table_association" "first" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.web_rt.id
}

resource "aws_route_table_association" "second" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.web_rt.id
}

resource "aws_instance" "Web_server" {
  ami                    = "ami-0cff7528ff583bf9a"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  subnet_id              = aws_subnet.web_subnet.id
  user_data              = file("apache.sh")
  tags = {
    Name = "Web Server"
  }

}

resource "aws_instance" "App_Server" {
  ami                    = "ami-0cff7528ff583bf9a"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  subnet_id              = aws_subnet.app_subnet.id
  user_data              = file("apache.sh")
  tags = {
    Name = "App Server"
  }

}

resource "aws_security_group" "lb_sg" {
  name        = "Web-SG"
  vpc_id      = aws_vpc.lu_vpc.id

  ingress {
    description = "HTTP into VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  tags = {
    Name = "LB_Server_SG"
  }
}

resource "aws_security_group" "web_server_sg" {
  name        = "Webserver_SG"
  vpc_id      = aws_vpc.lu_vpc.id

  ingress {
    description     = "Allow traffic from web layer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  tags = {
    Name = "Web_Server_SG"
  }
}


resource "aws_lb" "alb" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.web_subnet.id]
}

resource "aws_lb_target_group" "alb" {
  name     = "ALB"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lu_vpc.id
}

resource "aws_lb_target_group_attachment" "alb_1" {
  target_group_arn = aws_lb_target_group.alb.arn
  target_id        = aws_instance.Web_server.id
  port             = 80

  depends_on = [
    aws_instance.Web_server
  ]
}

resource "aws_lb_target_group_attachment" "alb_2" {
  target_group_arn = aws_lb_target_group.alb.arn
  target_id        = aws_instance.App_Server.id
  port             = 80

  depends_on = [
    aws_instance.App_Server
  ]
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }
}

resource "aws_db_instance" "RDS" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.28"
  instance_class       = "db.t2.micro"
  multi_az             = false
  name                 = "LUDB"
  username             = "admin"
  password             = "password"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.rds_group.id


  tags = {
    Name = "RDS database"
  }
}

resource "aws_db_subnet_group" "rds_group" {
  name       = "subnet group"
  subnet_ids = [aws_subnet.database_subnet.id]

  tags = {
    Name = "RDS subnet group"
  }
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.alb.dns_name
}