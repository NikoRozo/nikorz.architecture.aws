provider "aws" {
    region="us-east-1"
}

variable "name"            { }
variable "tags"            { }
# Variable Network
variable "vpc_cidr"        { }
variable "azs"             { }
variable "private_subnets" { }
variable "public_subnets"  { }
variable "one_nat"         { }
# Security Group ECS
variable "ingress_rule"    { }
# Variable ECS
variable "ami"                     { }
variable "instance_type"           { }
variable "key_name"                { }
variable "max_size"                { }
variable "min_size"                { }
variable "desired_capacity"        { }

module "network" {
    source = "./modules/network"

    name = var.name
    tags = var.tags
    vpc_cidr = var.vpc_cidr
    azs = var.azs
    private_subnets = var.private_subnets
    public_subnets = var.public_subnets
    one_nat = var.one_nat
}

#module "ecs" {
#    source = "./modules/ecs"

#    name = var.name
#    tags = var.tags
#    vpc_id = "${module.network.vpc_id}"
#    ami = var.ami
#    instance_type = var.instance_type
    #iam_instance_profile_id = var.iam_instance_profile_id
#    key_name = var.key_name
#    max_size = var.max_size
#    min_size = var.min_size
#    desired_capacity = var.desired_capacity
#    private_subnet_ids = "${module.network.private_subnet_ids}"
#    #load_balancers = var.load_balancers
#}

module "ecs_cluster" {
    source = "./modules/compute/ecs"

    name = var.name
    tags = var.tags
    vpc_id = "${module.network.vpc_id}"
    subnets = setunion(var.private_subnets, var.public_subnets)
    ingress_rule = var.ingress_rule
    ami = var.ami
    instance_type = var.instance_type
    key_name = var.key_name
    max_size = var.max_size
    min_size = var.min_size
    desired_capacity = var.desired_capacity
    private_subnet_ids = "${module.network.private_subnet_ids}"
}

resource "aws_iam_role" "ecs-service-role" {
    name                = "ecs-service-role"
    path                = "/"
    assume_role_policy  = data.aws_iam_policy_document.ecs-service-policy.json
}

resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
    role       = aws_iam_role.ecs-service-role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs-service-policy" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ecs.amazonaws.com"]
        }
    }
}

data "aws_ecs_task_definition" "wordpress" {
  task_definition = "${aws_ecs_task_definition.wordpress.family}"
}

resource "aws_ecs_task_definition" "wordpress" {
    family                = "hello_world"
    container_definitions = <<DEFINITION
[
  {
    "name": "wordpress",
    "links": [
      "mysql"
    ],
    "image": "wordpress",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "memory": 500,
    "cpu": 10
  },
  {
    "environment": [
      {
        "name": "MYSQL_ROOT_PASSWORD",
        "value": "password"
      }
    ],
    "name": "mysql",
    "image": "mysql",
    "cpu": 10,
    "memory": 500,
    "essential": true
  }
]
DEFINITION
}

resource "aws_ecs_service" "test-ecs-service" {
  	name            = "test-ecs-service"
  	iam_role        = aws_iam_role.ecs-service-role.name
  	cluster         = element(module.ecs_cluster.cluster_id, 0)
  	task_definition = "${aws_ecs_task_definition.wordpress.family}:${max("${aws_ecs_task_definition.wordpress.revision}", "${data.aws_ecs_task_definition.wordpress.revision}")}"
  	desired_count   = 1

  	load_balancer {
    	target_group_arn  = element("${module.ecs_cluster.alb-gp-arn}", 0)
    	container_port    = 80
    	container_name    = "wordpress"
	}
}

output "cluster_id" { value = "${module.ecs_cluster.cluster_id}" }