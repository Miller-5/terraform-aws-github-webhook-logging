
## The commented code below show us how we can create Lambda function with the correct permissions
## to authorize github webhook calls.
##
## In addition, a custom KMS key for lambda to pull the webhook secret as an environment variable.
## I've added root user access to this KMS key however this can be removed for extra layer of security



# ### Lambda Authorizer

# resource "aws_lambda_function" "github_webhook_authorizer" {
#   filename         = "lambda_scripts/zips/authorizer_function.zip"
#   function_name    = "github_webhook_authorizer"
#   role             = aws_iam_role.lambda_exec_role.arn
#   handler          = "webhookSecretAuth.lambda_handler"
#   runtime          = "python3.8"
#   source_code_hash = filebase64sha256("lambda_scripts/zips/authorizer_function.zip")

#   kms_key_arn = aws_kms_key.lambda_key.arn


#   environment {
#     variables = {
#       WEBHOOK_SECRET = random_password.webhook_secret.result
#     }
#   }

#   timeout = 5
# }

# resource "aws_lambda_permission" "allow_apigw_invoke" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.github_webhook_authorizer.function_name
#   principal     = "apigateway.amazonaws.com"

#   source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.github_webhook_api.id}/*"
# }

# resource "aws_iam_role" "lambda_exec_role" {
#   name = "lambda_exec_role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       }
#     ]
#   })

#   inline_policy {
#     name = "lambda_kms_permissions"

#     policy = jsonencode({
#       Version = "2012-10-17",
#       Statement = [
#         {
#           Effect = "Allow",
#           Action = [
#             "kms:Decrypt",
#             "kms:Encrypt",
#             "kms:GenerateDataKey*",
#             "kms:DescribeKey",
#           ],
#           Resource = "*"
#         }
#       ]
#     })
#   }
# }

# resource "aws_iam_policy_attachment" "lambda_basic_execution" {
#   name       = "lambda_basic_execution"
#   roles      = [aws_iam_role.lambda_exec_role.name]
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }


# ### KMS key for lambda

# resource "aws_kms_key" "lambda_key" {
#   description             = "KMS key for encrypting Lambda environment variables"
#   deletion_window_in_days = 10

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid: "Enable IAM User Permissions",
#         Effect: "Allow",
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         },
#         Action = "kms:*",
#         Resource = "*"
#       },
#       {
#         Sid: "Allow Lambda Role to Use the Key",
#         Effect: "Allow",
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.lambda_exec_role.name}"
#         },
#         Action = [
#           "kms:Decrypt",
#           "kms:Encrypt",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_kms_alias" "lambda_key_alias" {
#   name          = "alias/lambdaKey"
#   target_key_id = aws_kms_key.lambda_key.id
# }
