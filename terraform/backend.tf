terraform {
  backend "s3" {
    bucket         = var.s3_terraform_backend_name
    key            = "terraform-aws-github-webhook-logging/terraform.tfstate"
    region         = var.aws_region
  }
}