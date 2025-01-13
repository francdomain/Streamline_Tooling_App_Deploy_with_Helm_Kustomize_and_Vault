# Create a security group for the Aurora database to allow access from EKS
resource "aws_security_group" "aurora_sg" {
  name   = "aurora-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name        = "aurora-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "Subnet group for Aurora cluster"
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier  = "tooling-aurora-cluster"
  engine              = "aurora-mysql"
  engine_version      = "8.0.mysql_aurora.3.05.2"
  master_password     = var.db_password
  master_username     = var.db_username
  database_name       = var.db_name
  skip_final_snapshot = true

  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  count               = 2
  cluster_identifier  = aws_rds_cluster.aurora_cluster.id
  instance_class      = var.db_instance_class
  engine              = "aurora-mysql"
  publicly_accessible = true
}
