### Lambda function


resource "aws_lambda_function" "github_webhook_processor" {
  filename         = "lambda_scripts/zips/webhookProcessor_function.zip"
  function_name    = "githubWebhookProcessor"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "webhookProcessor.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("lambda_scripts/zips/webhookProcessor_function.zip")

  kms_key_arn   = aws_kms_key.lambda_key.arn
  layers        = [aws_lambda_layer_version.requests_layer.arn]



  environment {
    variables = {
      WEBHOOK_SECRET = random_password.webhook_secret.result
      S3_BUCKET      = aws_s3_bucket.github_webhook_bucket.id
      GITHUB_TOKEN   = var.github_token
    }
  }

  timeout = 10
}


### Lambda role w/ KMS inline policy

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Basic role

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "lambda_basic_execution"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SQS & S3 policy for lambda role

resource "aws_iam_policy" "lambda_sqs_s3_policy" {
  name        = "lambda_sqs_s3_policy"
  description = "Policy for Lambda to interact with SQS and S3"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"],
        Resource = aws_sqs_queue.webhook_sqs.arn
      },
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = "${aws_s3_bucket.github_webhook_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_s3_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_sqs_s3_policy.arn
}



### KMS key & role for lambda

resource "aws_kms_key" "lambda_key" {
  description             = "KMS key for encrypting Lambda environment variables"
  deletion_window_in_days = 30
}

resource "aws_iam_role_policy" "lambda_kms_policy" {
  name = "lambda_kms_permissions"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow", # This is for lambda access
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ],
        Resource = "${aws_kms_key.lambda_key.arn}"
      }
    ]
  })
}

resource "aws_kms_key_policy" "lambda_key_policy_update" {
  key_id = aws_kms_key.lambda_key.key_id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "Enable IAM User Permissions",
        Effect: "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = "kms:*",
        Resource = "*"
      },
      {
        Sid: "Allow Lambda Role to Use the Key",
        Effect: "Allow",
        Principal = {
          AWS = aws_iam_role.lambda_exec_role.arn
        },
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "${aws_kms_key.lambda_key.arn}"
      }
    ]
  })
}



resource "aws_kms_alias" "lambda_key_alias" {
  name          = "alias/lambdaKey"
  target_key_id = aws_kms_key.lambda_key.id
}


### SQS mapping for lambda

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.webhook_sqs.arn
  function_name    = aws_lambda_function.github_webhook_processor.arn
  enabled          = true

  batch_size = 1  # Process messages one at a time
}


### Lambda layer for request python package

resource "aws_lambda_layer_version" "requests_layer" {
  filename          = "lambda_scripts/zips/requests_layer.zip"
  layer_name        = "requests_layer"
  compatible_runtimes = ["python3.8"]
}