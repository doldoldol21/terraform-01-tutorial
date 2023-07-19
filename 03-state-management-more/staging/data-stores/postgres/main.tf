provider "aws" {
  region = "ap-northeast-2"
}

terraform {
  backend "s3" {
    key = "staging/data-stores/postgres/terraform.tfstate"
  }
}

data "aws_secretsmanager_secret_version" "credential" {
  secret_id = "db-credential"
}

locals {
  db_credential = jsondecode(
    data.aws_secretsmanager_secret_version.credential.secret_string
  )
}

resource "aws_db_instance" "mydb" {
  db_name = "mydb"
  engine = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"
  allocated_storage = 10

  skip_final_snapshot = true
  publicly_accessible = true

  username = local.db_credential.username
  password = local.db_credential.password
}