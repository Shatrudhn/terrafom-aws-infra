terraform {
  backend "s3" {
    bucket         = "tf-state-taxsutra"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tf-lock"
  }
}
