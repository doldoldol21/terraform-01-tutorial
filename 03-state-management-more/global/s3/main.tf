provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "02-terraform-state"

  # lifecycle {
  #   prevent_destroy = true
  # }
  force_destroy = true
}

# 버킷 파일의 버전 관리를 하는 옵션 
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 버킷 파일의 암호화 옵션
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 버킷의 퍼블릭 액세스 차단 옵션
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# terraform state의 잠금을 위한 DynamoDB
resource "aws_dynamodb_table" "terraform_state" {
  name         = "terraform_state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# terraform backend 설정
# s3와 dynamodb 를 terraform init, apply 한 후에 해당 block 추가 후 init.
# 약간 번거로움이 있는것같음. 안에 변수도 사용할 수 없다고 한다.
# terraform {
#   backend "s3" {
#     key = "global/s3/terraform.tfstate"
#   }
# }
