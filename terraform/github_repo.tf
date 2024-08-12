resource "github_repository" "whToAws" {
  name        = var.github_repository_name
  description = "This repo is a part of terraform-aws-github-webhook-logging repository"
  visibility = "public" # This is public for demonstration purposes  
}

resource "random_password" "webhook_secret" {
  length  = 32
  special = true
}

resource "github_repository_webhook" "pull_request_webhook" {
  repository = github_repository.whToAws.name
  events     = ["pull_request"]

  configuration {
    url          = "https://your-api-endpoint.com/webhook"
    content_type = "json"
    insecure_ssl = false
    secret       = random_password.webhook_secret.result
  }
}