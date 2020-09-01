#--------------------------------------------------------------
# Estos modulos crea los recursos necesarios para el alb
#--------------------------------------------------------------

variable "name"                { default = "alb" }
variable "tags"                { }
variable "security_groups"     { }
variable "vpc_id"              { }
variable "private_subnet_ids"  { }
variable "port"                { default = "80" }
variable "protocol"            { default = "HTTP" }

resource "aws_alb" "ecs-load-balancer" {
  name                = var.name
  security_groups     = var.security_groups
  subnets             = var.private_subnet_ids

  tags  = merge(
    var.tags,
    { Name = var.name },
  )
}

resource "aws_alb_target_group" "ecs-target-group" {
  name                = "${var.name}-gp"
  port                = var.port
  protocol            = var.protocol
  vpc_id              = var.vpc_id

  health_check {
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    interval            = "30"
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "5"
  }

  tags  = merge(
    var.tags,
    { Name = "${var.name}-gp" },
  )
}

resource "aws_alb_listener" "alb-listener" {
    load_balancer_arn = aws_alb.ecs-load-balancer.arn
    port              = var.port
    protocol          = var.protocol

    default_action {
        target_group_arn = aws_alb_target_group.ecs-target-group.arn
        type             = "forward"
    }
}

output "alb-name" { value = "${aws_alb.ecs-load-balancer.name}" }
output "alb-gp-arn" { value = "${aws_alb_target_group.ecs-target-group.arn}" }