resource "aws_s3_bucket" "github_webhook_bucket" {
  bucket = var.s3_bucket_name
}
