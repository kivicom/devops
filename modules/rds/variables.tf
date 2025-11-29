variable "name" {
  description = "Base name for RDS resources (identifiers, SG, subnet group)"
  type        = string
}

variable "use_aurora" {
  description = "If true — create Aurora cluster, otherwise create single RDS instance"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Engine for a standalone RDS instance (e.g. postgres, mysql)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version for a standalone RDS instance"
  type        = string
  default     = "14.11"
}

variable "aurora_engine" {
  description = "Engine for Aurora cluster (e.g. aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "aurora-postgresql"
}

variable "aurora_engine_version" {
  description = "Engine version for Aurora cluster"
  type        = string
  default     = "14.11"
}

variable "instance_class" {
  description = "Instance class for RDS / Aurora instances"
  type        = string
  default     = "db.t3.medium"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
}

variable "password" {
  description = "Master user password"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "allocated_storage" {
  description = "Allocated storage (in GiB) for a standalone RDS instance"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Enable Multi-AZ for a standalone RDS instance"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on database destroy (NOT for production!)"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID where database will be placed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for DB subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the database port"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "parameter_group_family" {
  description = "Family for aws_db_parameter_group (e.g. postgres14, mysql8.0)"
  type        = string
  default     = "postgres14"
}

variable "aurora_parameter_group_family" {
  description = "Family for aws_rds_cluster_parameter_group (e.g. aurora-postgresql14)"
  type        = string
  default     = "aurora-postgresql14"
}
