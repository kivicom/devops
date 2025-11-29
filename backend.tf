terraform {
  backend "s3" {
    bucket         = "tfstate-lesson5-igor-kurochkin-20251114-euc1"
    key            = "lesson-7/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}