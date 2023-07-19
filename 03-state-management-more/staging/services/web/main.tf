# AWS CLI 를 통해 액세스 키 정보 저장 필요

provider "aws" {
  region = "ap-northeast-2"
}

terraform {
  backend "s3" {
    key = "staging/services/web/terraform.tfstate"
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

resource "aws_instance" "example" {
  ami           = "ami-0c9c942bd7bf113a2"
  instance_type = "t2.micro"

  vpc_security_group_ids = [ aws_security_group.instance.id ]

  user_data = templatefile("user-data.sh", {
    server_port      = var.server_port
    postgres_address = data.terraform_remote_state.postgres.outputs.address
    postgres_port    = data.terraform_remote_state.postgres.outputs.port
  })

  user_data_replace_on_change = true
  tags = {
    Name = "web"
  }
}

data "terraform_remote_state" "postgres" {
  backend = "s3"

  config = {
    bucket = "02-terraform-state"
    key    = "staging/data-stores/postgres/terraform.tfstate"
    region = "ap-northeast-2"
  }

}
