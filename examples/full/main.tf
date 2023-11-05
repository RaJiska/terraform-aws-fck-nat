locals {
  name     = "fck-nat-example"
  vpc_cidr = "10.255.255.0/24"
}

data "aws_region" "current" {}

module "fck-nat" {
  source = "../"

  name               = local.name
  vpc_id             = aws_vpc.main.id
  subnet_id          = aws_subnet.public.id
  update_route_table = true
  route_table_id     = aws_route_table.private.id
  ha_mode            = false
}