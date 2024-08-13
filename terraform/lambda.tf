# Lambda autherization resouce can be found in apigw.tf

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

  inline_policy {
    name = "lambda_kms_permissions"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:GenerateDataKey*",
            "kms:DescribeKey",
          ],
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "lambda_basic_execution"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


### KMS key for lambda

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "lambda_key" {
  description             = "KMS key for encrypting Lambda environment variables"
  deletion_window_in_days = 10

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
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.lambda_exec_role.name}"
        },
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "lambda_key_alias" {
  name          = "alias/lambdaKey"
  target_key_id = aws_kms_key.lambda_key.id
}
