# ALB（ロードバランサー）
resource "aws_lb" "main_alb" {
  name               = "ticket-reserve-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]
  subnets         = [aws_subnet.public_a.id, aws_subnet.public_c.id]

  tags = {
    Name = "ticket-reserve-alb"
  }
}

# ターゲットグループ
resource "aws_lb_target_group" "main_tg" {
  name        = "ticket-reserve-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"

  #ヘルスチェック
  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "ticket-reserve-tg"
  }
}

# リスナー
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main_tg.arn
  }
}