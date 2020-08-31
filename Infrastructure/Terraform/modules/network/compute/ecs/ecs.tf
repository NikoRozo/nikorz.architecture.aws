#--------------------------------------------------------------
# Estos modulos crea los recursos necesarios el Cluster ECS
#--------------------------------------------------------------

# Global Variable
variable "name"                    { }
variable "tags"                    { }
# Variable Security
variable "vpc_id"                  { }
# Variable Launch
variable "ami"                     { }
variable "instance_type"           { }
variable "iam_instance_profile_id" { }
variable "key_name"                { }
# Variable Autoscalling
variable "max_size"                { default = 1 }
variable "min_size"                { default = 1 }
variable "desired_capacity"        { default = 1 }
variable "private_subnet_ids"      { }
variable "load_balancers"          { }

# Grupos de Seguridad
resource "aws_security_group" "instance" {
  name        = var.name
  vpc_id      = var.vpc_id

  tags  = merge(
    var.tags,
    { Name = "${var.name}" },
  )
}

# Separamos las reglas del aws_security_group porque luego podemos manipular el
# aws_security_group fuera de este módulo
resource "aws_security_group_rule" "outbound_internet_access" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instance.id
}

resource "aws_launch_configuration" "launch" {
  name_prefix          = "${var.name}_"
  image_id             = var.ami
  instance_type        = var.instance_type
  security_groups      = ["${aws_security_group.instance.id}"]
  # user_data            = data.template_file.user_data.rendered
  iam_instance_profile = var.iam_instance_profile_id
  key_name             = var.key_name
  tags  = merge(
    var.tags,
    { Name = "${var.name}" },
  )

  # aws_launch_configuration no se puede modificar.
  # Por lo tanto, usamos create_before_destroy para que se pueda crear una nueva configuración aws_launch_configuration modificada
  # antes de que el viejo sea destruido. Es por eso que usamos name_prefix en lugar de name.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name                 = "${var.name}"
  max_size             = var.max_size
  min_size             = var.min_size
  desired_capacity     = var.desired_capacity
  force_delete         = true
  launch_configuration = aws_launch_configuration.launch.id
  vpc_zone_identifier  = var.private_subnet_ids
  load_balancers       = var.load_balancers
  
  tags  = merge(
    var.tags,
    { Name = "${var.name}" },
  )
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.name}"
}

output "ecs_instance_security_group_id" { value = aws_security_group.instance.id }