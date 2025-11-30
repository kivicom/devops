############################
# Загальні налаштування
############################

variable "bucket_name" {
  description = "Назва S3 бакета для Terraform state"
  type        = string
  default     = "tfstate-final-igor-kurochkin-20251130-euc1"
}

variable "table_name" {
  description = "Назва DynamoDB таблиці для Terraform locks"
  type        = string
  default     = "terraform-locks-final"
}

variable "name" {
  description = "Назва проєкту (буде використана в тегах та іменах ресурсів)"
  type        = string
  default     = "django-app"
}

variable "region" {
  description = "AWS регіон для розгортання інфраструктури"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "Тип EC2 інстансів для worker-нод EKS кластера"
  type        = string
  default     = "t3.medium"
}

variable "repository_name" {
  description = "Назва ECR репозиторію для образів застосунку"
  type        = string
  default     = "dev-lesson-5-ecr"
}


############################
# Налаштування GitHub
############################

variable "github_pat" {
  description = "Персональний токен доступу GitHub (PAT) з правами repo"
  type        = string
}

variable "github_user" {
  description = "Імʼя користувача GitHub"
  type        = string
}

variable "github_repo_url" {
  description = "URL GitHub репозиторію з кодом та Helm-чартами"
  type        = string
}

variable "github_branch" {
  description = "Гілка GitHub репозиторію для Jenkins / Argo CD"
  type        = string
}


############################
# Налаштування RDS / Aurora
############################

variable "rds_use_aurora" {
  description = "Використовувати Aurora (true) або стандартний RDS (false)"
  type        = bool
  default     = true
}

variable "rds_username" {
  description = "Імʼя користувача бази даних RDS / Aurora"
  type        = string
  default     = "django_user"
}

variable "rds_password" {
  description = "Пароль користувача бази даних RDS / Aurora"
  type        = string
  sensitive   = true
}

variable "rds_database_name" {
  description = "Назва бази даних RDS / Aurora"
  type        = string
  default     = "django_db"
}

variable "rds_publicly_accessible" {
  description = "Чи має бути база даних RDS доступна з публічного інтернету"
  type        = bool
  default     = false
}

variable "rds_multi_az" {
  description = "Увімкнути Multi-AZ для високої доступності RDS"
  type        = bool
  default     = true
}

variable "rds_instance_class" {
  description = "Клас інстанса для RDS / Aurora інстансів"
  type        = string
  default     = "db.t4g.medium"
}

variable "rds_backup_retention_period" {
  description = "Період зберігання бекапів RDS (у днях)"
  type        = string
  default     = "7"
}

variable "rds_aurora_engine" {
  description = "Двигун (engine) для Aurora RDS"
  type        = string
  default     = "aurora-postgresql"
}

variable "rds_aurora_engine_version" {
  description = "Версія двигуна для Aurora RDS"
  type        = string
  default     = "15.6"
}

variable "rds_aurora_parameter_group_family" {
  description = "Parameter group family для Aurora RDS"
  type        = string
  default     = "aurora-postgresql15"
}

variable "rds_instance_engine" {
  description = "Двигун (engine) для стандартного RDS інстанса"
  type        = string
  default     = "postgres"
}

variable "rds_instance_engine_version" {
  description = "Версія двигуна для стандартного RDS інстанса"
  type        = string
  default     = "17.2"
}

variable "rds_instance_parameter_group_family" {
  description = "Parameter group family для стандартного RDS інстанса"
  type        = string
  default     = "postgres17"
}
