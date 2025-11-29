resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1

  identifier        = "${var.name}-db"
  allocated_storage = var.allocated_storage
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  db_name           = var.db_name
  username          = var.username
  password          = var.password
  port              = var.port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.this[0].name

  multi_az            = var.multi_az
  publicly_accessible = false
  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = false
  apply_immediately   = true

  tags = {
    Name = "${var.name}-db-instance"
  }
}
