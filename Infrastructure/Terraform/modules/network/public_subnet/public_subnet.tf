#--------------------------------------------------------------
# Este Modulo crea los recursos necesario para una subred publica
#--------------------------------------------------------------

variable "name"   { default = "public" }
variable "tags"   { }
variable "vpc_id" { }
variable "cidrs"  { }
variable "azs"    { }

resource "aws_internet_gateway" "public" {
  vpc_id = var.vpc_id

  tags  = merge(
    var.tags,
    { Name = "${var.name}" },
  )
}

resource "aws_subnet" "public" {
  vpc_id            = var.vpc_id
  cidr_block        = element(split(",", var.cidrs), count.index)
  availability_zone = element(split(",", var.azs), count.index)
  count             = length(split(",", var.cidrs))

  tags  = merge(
    var.tags,
    { Name = "${var.name}.${element(split(",", var.azs), count.index)}" },
  )

  lifecycle { create_before_destroy = true }

  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id
  count  = length(split(",", var.cidrs))

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.public.id
  }

  tags  = merge(
    var.tags,
    { Name = "${var.name}.${element(split(",", var.azs), count.index)}" },
  )

}

resource "aws_route_table_association" "public" {
  count          = length(split(",", var.cidrs))
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[count.index].id
}

output "subnet_ids" { value = "${join(",", aws_subnet.public.*.id)}" }