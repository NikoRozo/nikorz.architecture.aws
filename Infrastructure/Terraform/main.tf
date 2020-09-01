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

output "sg_id" { value = "${module.ecs_cluster.cluster_id}" }