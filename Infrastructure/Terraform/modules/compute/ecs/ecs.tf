#--------------------------------------------------------------
# Estos modulos crea los recursos necesarios el Cluster ECS
#--------------------------------------------------------------

# Global Variable
variable "name"                { }
variable "tags"                { }
# Variable Security
variable "vpc_id"              { }
variable "subnets"             { }
variable "ingress_rule"        { }
# Variable Launch
variable "ami"                 { }
variable "instance_type"       { }
variable "key_name"            { }
# Variable Autoscalling
variable "max_size"           { default = 1 }
variable "min_size"           { default = 1 }
variable "desired_capacity"   { default = 1 }
variable "private_subnet_ids" { }
# Variable ALB
variable "port"               { default = "80" }
variable "protocol"           { default = "HTTP" }

module "sg-ecs" {
    source = "../../security/security_group"

    name = var.name
    tags = var.tags
    vpc_id = var.vpc_id
    ingress_rule = var.ingress_rule
    cidrs = var.subnets
}

module "alb" {
    source = "./alb"

    name = "${var.name}-alb"
    tags = var.tags
    security_groups = "${module.sg-ecs.sg_id}"
    vpc_id = var.vpc_id
    private_subnet_ids = var.private_subnet_ids
    port = var.port
    protocol = var.protocol
}

module "launch" {
    source = "./launch_config"
    
    name = var.name
    ami = var.ami
    instance_type = var.instance_type
    key_name = var.key_name
    security_groups = "${module.sg-ecs.sg_id}"
    ecs_cluster = "${var.name}-ecs-cluster"
}

module "auntoscalling" {
    source = "./autoscalling"
    
    name = var.name
    max_size = var.max_size
    min_size = var.min_size
    desired_capacity = var.desired_capacity
    private_subnet_ids = var.private_subnet_ids
    launch_config = "${module.launch.launch_name}"
}


resource "aws_ecs_cluster" "ecs-cluster" {
    name = "${var.name}-ecs-cluster"
}

output "cluster_id" { value = "${aws_ecs_cluster.ecs-cluster.*.id}" }
output "alb-gp-arn" { value = "${module.alb.*.alb-gp-arn}" }