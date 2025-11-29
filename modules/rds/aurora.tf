resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = "${var.name}-aurora-cluster"
  engine             = var.aurora_engine
  engine_version     = var.aurora_engine_version
  database_name      = var.db_name
  master_username    = var.username
  master_password    = var.password
  port               = var.port

  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this[0].name

  storage_encrypted   = true
  deletion_protection = false
  skip_final_snapshot = var.skip_final_snapshot
  apply_immediately   = true

  tags = {
    Name = "${var.name}-aurora-cluster"
  }
}

resource "aws_rds_cluster_instance" "this" {
  count = var.use_aurora ? 1 : 0

  identifier          = "${var.name}-aurora-instance-1"
  cluster_identifier  = aws_rds_cluster.this[0].id
  instance_class      = var.instance_class
  engine              = var.aurora_engine
  engine_version      = var.aurora_engine_version
  publicly_accessible = false

  tags = {
    Name = "${var.name}-aurora-instance-1"
  }
}
