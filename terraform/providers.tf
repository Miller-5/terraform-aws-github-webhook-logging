terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "5.62.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

provider "aws" {
  region = "us-west-2"
}