locals {
  name     = "fck-nat-example"
  vpc_cidr = "10.255.255.0/24"
}

data "aws_region" "current" {}

module "fck-nat" {
  source = "../../"

  name      = local.name
  vpc_id    = aws_vpc.main.id
  subnet_id = aws_subnet.public.id
  ha_mode   = true
  ha_mode_enabled_metrics = [
    "GroupInServiceInstances"
  ]

  update_route_tables = true
  route_tables_ids = {
    "private" = aws_route_table.private.id
  }
}