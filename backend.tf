terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket        = "tfstate-lesson5-igor-kurochkin-20251114-euc1"
    key           = "lesson-5/terraform.tfstate"
    region        = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt       = true
  }
}
