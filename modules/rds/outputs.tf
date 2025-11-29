output "db_endpoint" {
  description = "Primary write endpoint of the database (RDS instance or Aurora cluster)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
}

output "reader_endpoint" {
  description = "Reader endpoint for Aurora (or same as primary for standalone RDS)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : aws_db_instance.this[0].address
}

output "port" {
  description = "Database port"
  value       = var.port
}

output "security_group_id" {
  description = "Security group ID attached to the database"
  value       = aws_security_group.this.id
}

output "subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.this.name
}

output "engine_in_use" {
  description = "Engine actually used (Aurora or standalone)"
  value       = var.use_aurora ? var.aurora_engine : var.engine
}
