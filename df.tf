# DBサブネットグループの作成
resource "aws_db_subnet_group" "main" {
  name       = "ticket-reserve-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_c.id]

  tags = {
    Name = "ticket-reserve-db-subnet-group"
  }
}

# Auroraクラスター（MySQL互換）
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier          = "ticket-reserve-aurora-cluster"
  engine                      = "aurora-mysql"
  engine_version              = "8.0.mysql_aurora.3.04.1"
  database_name               = "ticketdb"
  master_username             = "admin"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  skip_final_snapshot = true

  tags = {
    Name = "ticket-reserve-aurora-cluster"
  }
}

# Auroraインスタンス
resource "aws_rds_cluster_instance" "aurora-instance" {
  identifier         = "ticket-reserve-aurora-instance-1"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.t4g.medium"
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version

  tags = {
    Name = "ticket-reserve-aurora-instance-1"
  }
}
