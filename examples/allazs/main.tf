module "nat-per-az" {
  # checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash
  # checkov:skip=CKV_TF_2:Ensure Terraform module sources use a tag with a version number
  source = "../.."

  name                 = "fck-nat"
  env                  = "dev"
  use_cloudwatch_agent = true
  use_spot_instances   = false # low availability in some AZs

}
