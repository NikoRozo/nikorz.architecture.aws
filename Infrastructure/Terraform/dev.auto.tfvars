# Global variables Proyect
name ="aws-nikorz"
tags = { Enviroment="Qa", Owner="Niko" }
# Variable por VPC
vpc_cidr        = "10.139.0.0/16"
azs             = ["us-east-1a", "us-east-1c"] # AZs are region specific
private_subnets = ["10.139.1.0/24", "10.139.2.0/24"] # Creating one private subnet per AZ
public_subnets  = ["10.139.11.0/24", "10.139.12.0/24"] # Creating one public subnet per AZ
one_nat         = true # False, creating one nat per AZ
# Variable Security Group
ingress_rule = [
    {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    },
    {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    },
    {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
]

# variable ECS
ami                       = "ami-02354e95b39ca8dec"
instance_type             = "t2.micro"
key_name                  = "nikokp"
max_size                  = 2
min_size                  = 2
desired_capacity          = 2