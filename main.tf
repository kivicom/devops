provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Project     = "lesson-5"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "tfstate-lesson5-igor-kurochkin-20251114-euc1"
  table_name  = "terraform-locks"
  aws_region  = "eu-central-1"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  vpc_name           = "dev-lesson-5-vpc"
  single_nat_gateway = true
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "dev-lesson-5-ecr"
  scan_on_push = true
  mutable      = "IMMUTABLE"
}
