provider "aws" {
  region = "ap-northeast-2"  # 사용하는 리전에 맞게 변경하세요
}


# 사용자 데이터 변수 정의
variable "user_data_file" {
  default = "user_data.sh"
}

data "template_file" "user_data" {
  template = file("${path.module}/${var.user_data_file}")
}

resource "aws_vpc" "MyVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC"
  }
}

resource "aws_internet_gateway" "MyIGW" {
  vpc_id = aws_vpc.MyVPC.id
  tags = {
    Name = "IGW"
  }
}

# resource "aws_internet_gateway_attachment" "MyIGWAttachment" {
#   vpc_id             = aws_vpc.MyVPC.id
#   internet_gateway_id = aws_internet_gateway.MyIGW.id
# }

resource "aws_route_table" "MyPublicRT" {
  vpc_id = aws_vpc.MyVPC.id
  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route" "DefaultPublicRoute" {
  route_table_id         = aws_route_table.MyPublicRT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.MyIGW.id
}

resource "aws_subnet" "MyPublicSN" {
  vpc_id            = aws_vpc.MyVPC.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-SN"
  }
}

resource "aws_subnet" "MyPublicSN2" {
  vpc_id            = aws_vpc.MyVPC.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-SN-2"
  }
}

resource "aws_security_group" "WebSG" {
  name        = "Web-SG"
  description = "WEB Security Group"
  vpc_id      = aws_vpc.MyVPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-SG"
  }
}

resource "aws_instance" "DVWAEC2" {
  instance_type = "t2.micro"
  ami           = "ami-050a4617492ff5822"
  key_name      = "eyjo-ec2"  # 여기에 키페어의 이름을 입력하세요
  tags = {
    Name = "DVWA-EC2-EYJO"
  }

  subnet_id   = aws_subnet.MyPublicSN.id  # 서브넷 ID 지정
  vpc_security_group_ids = [aws_security_group.WebSG.id]

  user_data = data.template_file.user_data.rendered  # 사용자 데이터 변수 할당
}

resource "aws_route_table_association" "MyPublicSNRTAssociation" {
  subnet_id      = aws_subnet.MyPublicSN.id
  route_table_id = aws_route_table.MyPublicRT.id
}

resource "aws_route_table_association" "MyPublicSN2RTAssociation" {
  subnet_id      = aws_subnet.MyPublicSN2.id
  route_table_id = aws_route_table.MyPublicRT.id
}

resource "aws_lb_target_group" "ALBTG" {
  name        = "ALB-TG"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.MyVPC.id

  health_check {
    path = "/login.php"
  }
}

resource "aws_lb_target_group_attachment" "ALBTGAttachment" {
  target_group_arn = aws_lb_target_group.ALBTG.arn
  target_id        = aws_instance.DVWAEC2.id
}

resource "aws_lb" "MyALB" {
  name               = "ALB"
  load_balancer_type = "application"
  subnets            = [aws_subnet.MyPublicSN.id, aws_subnet.MyPublicSN2.id]
  security_groups    = [aws_security_group.WebSG.id]
}

resource "aws_lb_listener" "ALBListener" {
  load_balancer_arn = aws_lb.MyALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ALBTG.arn
  }
}

data "aws_availability_zones" "available" {}

