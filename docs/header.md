# Terraform fck-nat

## Introduction

A Terraform module for deploying NAT Instances using [fck-nat](https://github.com/AndrewGuenther/fck-nat). The (f)easible (c)ost (k)onfigurable NAT!
The following is a list of features available with this module:
- High-availability mode achieved through a floating internal ENI automatically attached to instances being started by
an ASG
- Optional consistent static IP via EIP re-attachment to the internet facing ENI
- Cloudwatch metrics reported similar to those available with the managed NAT Gateway
- Use of spot instances instead of on-demand for reduced costs

## Example

```hcl
module "fck-nat" {
  source = "git::https://github.com/RaJiska/terraform-aws-fck-nat.git"

  name                 = "my-fck-nat"
  vpc_id               = "vpc-abc1234"
  subnet_id            = "subnet-abc1234"
  # ha_mode              = true                 # Enables high-availability mode
  # eip_allocation_ids   = ["eipalloc-abc1234"] # Allocation ID of an existing EIP
  # use_cloudwatch_agent = true                 # Enables Cloudwatch agent and have metrics reported

  update_route_tables = true
  route_tables_ids = {
    "your-rtb-name-A" = "rtb-abc1234Foo"
    "your-rtb-name-B" = "rtb-abc1234Bar"
  }
}
```
