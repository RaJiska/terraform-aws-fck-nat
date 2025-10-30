module "nat-instance-per-az" {
  # checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash
  # checkov:skip=CKV_TF_2:Ensure Terraform module sources use a tag with a version number
  source               = "../.."
  for_each             = { for k, v in data.aws_availability_zones.azs.zone_ids : k => v if var.deploy_nat_per_az }
  name                 = "${var.name}-${each.value}"
  vpc_id               = aws_vpc.main.id
  subnet_id            = aws_subnet.public[each.value].id
  use_cloudwatch_agent = var.use_cloudwatch_agent
  instance_type        = var.instance_type
  ha_mode              = var.ha_mode
  use_spot_instances   = var.use_spot_instances # low availability in some AZs
  update_route_tables  = true
  route_tables_ids = {
    private = aws_route_table.private[each.value].id
  }
  tags = {
    Name = "nat-${var.name}-${each.value}"
  }
}

module "single-nat-instance" {
  # checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash
  # checkov:skip=CKV_TF_2:Ensure Terraform module sources use a tag with a version number
  source               = "../.."
  count                = var.deploy_single_nat ? 1 : 0
  name                 = var.name
  vpc_id               = aws_vpc.main.id
  subnet_id            = aws_subnet.public[data.aws_availability_zones.azs.zone_ids[0]].id
  use_cloudwatch_agent = var.use_cloudwatch_agent
  instance_type        = var.instance_type
  ha_mode              = var.ha_mode
  use_spot_instances   = var.use_spot_instances # low availability in some AZs
  update_route_tables  = true
  route_tables_ids     = { for k in data.aws_availability_zones.azs.zone_ids[*] : k => aws_route_table.private[k].id }
  tags = {
    Name = "nat-${var.name}"
  }
}
