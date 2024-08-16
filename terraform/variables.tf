### AWS

variable "aws_region" {
  default = "us-west-2"
}

data "aws_caller_identity" "current" {}

variable "s3_bucket_name" {}


### Github

variable "github_repository_name" {
  default = "github-webhook-logging-to-aws-example"
}