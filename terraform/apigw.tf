### API Gateway

resource "aws_api_gateway_rest_api" "github_webhook_api" {
  name        = "GitHubWebhookAPI"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  description = "API for handling GitHub webhooks"

}

resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  parent_id   = aws_api_gateway_rest_api.github_webhook_api.root_resource_id
  path_part   = "webhook"
}

## Lambda authorizer

# resource "aws_api_gateway_authorizer" "github_webhook_authorizer" {
#   rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
#   name        = "GitHubWebhookAuthorizer"
#   type        = "TOKEN"
#   authorizer_uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.github_webhook_authorizer.arn}/invocations"
#   identity_source = "method.request.header.Authorization"
# }

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.github_webhook_api.id
  resource_id   = aws_api_gateway_resource.webhook.id
  http_method   = "POST"
  authorization = "NONE"
    # Basic Authorization happens by API GW and HMAC Validation by lambda function later on



## Lambda authorizer implementation

#   authorization = "CUSTOM"
#   authorizer_id = aws_api_gateway_authorizer.github_webhook_authorizer.id
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
#set($signatureHeader = $input.params('X-Hub-Signature-256'))
#set($inputRoot = $input.path('$'))
#if($inputRoot.action == "closed" && $inputRoot.pull_request.merged == true && $signatureHeader.length() == 71)
Action=SendMessage&MessageBody=$input.body
#else
  #set($context.responseOverride.status = 200)
  {"status":"ignored"}
#end
EOF
  }

  credentials = aws_iam_role.api_gateway_sqs_role.arn
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  resource_id = aws_api_gateway_resource.webhook.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

    response_templates = {
    "application/json" = ""
  }
}

resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  resource_id = aws_api_gateway_resource.webhook.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

}



resource "aws_api_gateway_deployment" "github_webhook_deployment" {
  depends_on = [
    aws_api_gateway_integration.sqs_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  stage_name  = "prod"

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.github_webhook_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
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
