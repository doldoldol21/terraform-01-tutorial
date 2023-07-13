# AWS CLI 를 통해 액세스 키 정보 저장 필요

provider "aws" {
  region = "ap-northeast-2"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]

  }
}

resource "aws_launch_configuration" "example" {
  image_id        = "ami-0c9c942bd7bf113a2"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]
  
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  # Required with an autoscaling group. (autoscaling 필수)
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "instance" {
  name = "web"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# autoscaling을 사용하면 가용성 영역(availability_zones)을 지정 안할 경우 vpc내에 사용 가능한 서브넷 중 무작위로 설정되는데
# 가용성 영역 중 ec2를 생성할 수 없는 가용성이 있어서 autoscaling group을 2개 생성해서 각각 사용하는 가용성 영역을 지정해주었다.

resource "aws_autoscaling_group" "web-a" {
  launch_configuration = aws_launch_configuration.example.name
  #   vpc_zone_identifier  = data.aws_subnets.default.ids
  availability_zones = ["ap-northeast-2a"]

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 1
  max_size = 2

  tag {
    key                 = "Name"
    value               = "web-a"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "web-c" {
  launch_configuration = aws_launch_configuration.example.name
  #   vpc_zone_identifier  = data.aws_subnets.default.ids
  availability_zones = ["ap-northeast-2c"]

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 1
  max_size = 2

  tag {
    key                 = "Name"
    value               = "web-c"
    propagate_at_launch = true
  }
}

resource "aws_lb" "example" {
  name               = "web"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  # By default, it just shows a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "web-alb"

  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbount requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "asg" {
  name     = "web-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }

}
