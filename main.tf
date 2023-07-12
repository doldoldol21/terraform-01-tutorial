# AWS CLI 를 통해 액세스 키 정보 저장 필요

provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_instance" "example" {
  ami = "ami-0221383823221c3ce"
  instance_type = "t3.micro"

  tags = {
    Name = "my-amazon-linux"
  }
}