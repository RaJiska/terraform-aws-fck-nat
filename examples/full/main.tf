locals {
  name         = "fck-nat-example"
  vpc_cidr     = "10.255.255.0/24"
  ipv6_support = true
}

data "aws_region" "current" {}

module "fck-nat" {
  source = "../../"

  name      = local.name
  vpc_id    = aws_vpc.main.id
  subnet_id = aws_subnet.public.id
  ha_mode   = false
  use_nat64 = local.ipv6_support

  update_route_table = true
  route_tables_ids = {
    "private" = aws_route_table.private.id
  }
  route_tables6_ids = {
    "public" = aws_route_table.public6[0].id
  }
}
