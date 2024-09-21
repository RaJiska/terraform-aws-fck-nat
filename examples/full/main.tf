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

  # Pre-release version of the AMI
  # Replace the below with the ID according to your region and architecture: https://github.com/AndrewGuenther/fck-nat/issues/41#issuecomment-2036191471
  ami_id = "ami-0c2e470170d2a48e3" # ARM us-east-1

  update_route_table = true
  route_tables_ids = {
    "private" = aws_route_table.private.id
  }
  route_tables6_ids = {
    "public" = aws_route_table.public6[0].id
  }
}
