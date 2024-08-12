resource "github_repository" "webhookToAws" {
  name        = var.github_repository_name
  description = "This repo is a part of Miller-5/terraform-aws-github-webhook-logging repository"
  private     = false # This is false for demonstration purposes  
}

resource "random_password" "webhook_secret" {
  length  = 32
  special = true
}

resource "github_repository_webhook" "pull_request_webhook" {
  repository = github_repository.webhookToAws.name
  events     = ["pull_request"]

  configuration {
    url          = "https://your-api-endpoint.com/webhook"
    content_type = "json"
    insecure_ssl = false
    secret       = random_password.webhook_secret.result
  }
}