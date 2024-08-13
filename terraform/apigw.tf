### API Gateway

resource "aws_api_gateway_rest_api" "github_webhook_api" {
  name        = "GitHubWebhookAPI"
}

resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  parent_id   = aws_api_gateway_rest_api.github_webhook_api.root_resource_id
  path_part   = "webhook"
}

resource "aws_api_gateway_authorizer" "github_webhook_authorizer" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  name        = "GitHubWebhookAuthorizer"
  type        = "TOKEN"
  authorizer_uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.github_webhook_authorizer.arn}/invocations"
  identity_source = "method.request.header.Authorization"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.github_webhook_api.id
  resource_id   = aws_api_gateway_resource.webhook.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.github_webhook_authorizer.id
}


resource "aws_api_gateway_integration" "sqs_integration" {
  rest_api_id             = aws_api_gateway_rest_api.github_webhook_api.id
  resource_id             = aws_api_gateway_resource.webhook.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:sqs:path/${data.aws_caller_identity.current.account_id}/${aws_sqs_queue.webhook_sqs.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = <<EOF
{
  "Action": "SendMessage",
  "MessageBody": "$util.base64Encode($input.body)"
}
EOF
  }

  credentials = aws_iam_role.api_gateway_sqs_role.arn
}

resource "aws_api_gateway_integration_response" "default_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  resource_id = aws_api_gateway_resource.webhook.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"  # Ensure you have an integration response for each status code you expect

  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }
}

resource "aws_api_gateway_method_response" "default_method_response" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  resource_id = aws_api_gateway_resource.webhook.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"  # Ensure this matches the status code in the integration response

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}



resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  resource_id = aws_api_gateway_resource.webhook.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_deployment" "github_webhook_deployment" {
  depends_on  = [aws_api_gateway_integration.sqs_integration]
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  stage_name  = "prod"
}



### Lambda Authorizer

resource "aws_lambda_function" "github_webhook_authorizer" {
  filename         = "authorizer_function.zip"
  function_name    = "github_webhook_authorizer"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "webhookSecretAuth.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("authorizer_function.zip")

  kms_key_arn = aws_kms_key.lambda_key.arn


  environment {
    variables = {
      WEBHOOK_SECRET = random_password.webhook_secret.result
    }
  }

  timeout = 5
}

resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.github_webhook_authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.github_webhook_api.id}/*"
}


### Roles

resource "aws_iam_role" "api_gateway_sqs_role" {
  name = "api-gateway-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "sqs_send_message"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "sqs:SendMessage"
          ],
          Resource = aws_sqs_queue.webhook_sqs.arn
        }
      ]
    })
  }
}
