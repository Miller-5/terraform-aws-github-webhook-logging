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
            "kms:DescribeKey"
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



data "aws_kms_key" "lambda_default_key" {
  key_id = "alias/aws/lambda"
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "lambda_default_key_policy" {
  key_id = data.aws_kms_key.lambda_default_key.key_id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AllowLambdaDecrypt",
        Effect = "Allow",
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
