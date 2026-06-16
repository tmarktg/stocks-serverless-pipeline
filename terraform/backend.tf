terraform {
  backend "s3" {
    bucket = "stocks-serverless-tfstate-102885960566"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
