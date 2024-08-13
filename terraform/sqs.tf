resource "aws_sqs_queue" "webhook_sqs" {
  name = "github_webhook_sqs"
}

