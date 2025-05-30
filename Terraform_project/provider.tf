terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform"
}

provider "aws" {
  region  = "us-west-1"
  alias   = "west"
  profile = "terraform"
}