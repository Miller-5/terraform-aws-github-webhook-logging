## Main SQS

resource "aws_sqs_queue" "webhook_sqs" {
  name = "github_webhook_sqs"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.webhook_dlq_sqs.arn
    maxReceiveCount     = 5  # Number of times a message is retried before being sent to the DLQ
  })
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.webhook_sqs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.api_gateway_sqs_role.arn
        },
        Action = "sqs:SendMessage",
        Resource = aws_sqs_queue.webhook_sqs.arn
      }
    ]
  })
}

## DLQ

resource "aws_sqs_queue" "webhook_dlq_sqs" {
  name = "github_webhook_DLQ_sqs"
}
