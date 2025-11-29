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

module "eks" {
  source = "./modules/eks"

  # имя и версия кластера
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # забираем VPC и приватные сабсети из локального модуля vpc
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # имя node group — можно привязать к имени кластера
  node_group_name = "${var.cluster_name}-ng"

  # размеры node group — имена СЛЕВА совпадают с variables в modules/eks/variables.tf
  node_desired_size = var.node_group_desired_size
  node_min_size     = var.node_group_min_size
  node_max_size     = var.node_group_max_size
}

module "jenkins" {
  source = "./modules/jenkins"

  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_cert  = module.eks.cluster_certificate_authority_data

  namespace = "jenkins"
}

module "argo_cd" {
  source = "./modules/argo_cd"

  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_cert  = module.eks.cluster_certificate_authority_data

  namespace       = "argocd"
  apps_repo_url   = "https://github.com/kivicom/devops.git"
  apps_repo_path  = "charts/django-app"
  apps_target_rev = "lesson-8-9"
}

module "rds" {
  source = "./modules/rds"

  name       = "lesson10-app-db"
  use_aurora = false # true → Aurora, false → звичайна RDS

  # Мережа
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Налаштування БД (standalone RDS)
  engine         = "postgres"
  engine_version = "14.11"
  aurora_engine  = "aurora-postgresql"

  instance_class = "db.t3.micro"
  port           = 5432

  db_name  = "appdb"
  username = "dbadmin"
  password = "change_me_please" #  tfvars

  multi_az            = false
  allocated_storage   = 20
  skip_final_snapshot = true

  # Доступ до БД
  allowed_cidr_blocks           = ["10.0.0.0/16"]
  parameter_group_family        = "postgres14"
  aurora_parameter_group_family = "aurora-postgresql14"
}
