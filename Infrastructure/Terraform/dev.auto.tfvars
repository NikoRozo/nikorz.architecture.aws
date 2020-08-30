name ="aws-nikorz"
tags = { Enviroment="Qa", Owner="Niko" }

vpc_cidr        = "10.139.0.0/16"
azs             = "us-east-1a,us-east-1c" # AZs are region specific
private_subnets = "10.139.1.0/24,10.139.2.0/24" # Creating one private subnet per AZ
public_subnets  = "10.139.11.0/24,10.139.12.0/24" # Creating one public subnet per AZ