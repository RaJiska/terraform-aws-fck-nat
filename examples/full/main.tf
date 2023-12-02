locals {
  name     = "fck-nat-example"
  vpc_cidr = "10.255.255.0/24"

  trusted_networks = [
    "123.123.123.123/32"
  ]
}

data "aws_region" "current" {}

module "fck-nat" {
  source = "../../"

  name      = local.name
  vpc_id    = aws_vpc.main.id
  subnet_id = aws_subnet.public.id
  ha_mode   = true

  update_route_tables = true
  route_tables_ids = {
    "private" = aws_route_table.private.id
  }

  additional_security_group_ids = [aws_security_group.additional_security_group.id]
}

resource "aws_security_group" "additional_security_group" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.trusted_networks
  }
}
