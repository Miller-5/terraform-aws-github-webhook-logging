terraform {
  backend "s3" {
    bucket         = "paul-miller-tf-backend"
    key            = "terraform-aws-github-webhook-logging/terraform.tfstate"
    region         = "us-west-2"
  }
}