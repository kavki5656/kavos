# ALB用セキュリティグループ
resource "aws_security_group" "alb_sg" {
  name        = "ticket-reserve-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main_vpc.id

  # インターネットからのHTTPアクセスを許可
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # インターネットからのHTTPSアクセスを許可
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # アウトバウンドは全許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# ECS用セキュリティグループ
resource "aws_security_group" "ecs_sg" {
  name        = "ticket-reserve-ecs-sg"
  description = "Security group for ECS"
  vpc_id      = aws_vpc.main_vpc.id

  # ALBからのアクセスだけを許可
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-sg"
  }
}

# Aurora用セキュリティグループ
resource "aws_security_group" "db_sg" {
  name        = "ticket-reserve-db-sg"
  description = "Security group for Aurora DB"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}