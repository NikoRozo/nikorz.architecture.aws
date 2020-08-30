provider "aws" {
    region="us-east-1"
}

variable "name"            { }
variable "tags"            { }
variable "vpc_cidr"        { }
variable "azs"             { }
variable "private_subnets" { }
variable "public_subnets"  { }

module "app-demo-s3" {
    source = "./modules/network"
    name = var.name
    tags = var.tags
    vpc_cidr = var.vpc_cidr
    azs = var.azs
    private_subnets = var.private_subnets
    public_subnets = var.public_subnets
}