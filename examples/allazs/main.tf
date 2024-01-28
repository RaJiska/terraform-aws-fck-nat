locals {
  name     = "fck-nat-allazs"
  vpc_cidr = "10.255.0.0/16"
}

data "aws_region" "current" {}

data "aws_availability_zones" "azs" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "fck-nat" {
  source   = "../../"
  for_each = toset(data.aws_availability_zones.azs.zone_ids)

  name      = "${local.name}-nat-${each.key}"
  vpc_id    = aws_vpc.main.id
  subnet_id = aws_subnet.public[each.key].id

  update_route_tables = true
  route_tables_ids = {
    "private" = aws_route_table.private[each.key].id
  }

  tags = {
    Name = "${local.name}-fck-nat-${each.key}"
  }
}
