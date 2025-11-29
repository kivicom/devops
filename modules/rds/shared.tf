resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name}-db-subnet-group"
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name}-db-sg"
  description = "Security group for ${var.name} database"
  vpc_id      = var.vpc_id

  ingress {
    description = "DB access"
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-db-sg"
  }
}

# Parameter group для звичайної RDS
resource "aws_db_parameter_group" "this" {
  count  = var.use_aurora ? 0 : 1
  name   = "${var.name}-params"
  family = var.parameter_group_family

  parameter {
    name         = "max_connections"
    value        = "100"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_statement"
    value        = "all"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "work_mem"
    value        = "4096"
    apply_method = "pending-reboot"
  }
}

# Parameter group для Aurora
resource "aws_rds_cluster_parameter_group" "this" {
  count  = var.use_aurora ? 1 : 0
  name   = "${var.name}-aurora-params"
  family = var.aurora_parameter_group_family

  parameter {
    name         = "max_connections"
    value        = "100"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_statement"
    value        = "all"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "work_mem"
    value        = "4096"
    apply_method = "pending-reboot"
  }
}
