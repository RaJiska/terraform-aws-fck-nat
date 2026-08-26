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
  source = "git::https://github.com/jperez3/terraform-aws-fck-nat.git"

  env   = "dev"
  name  = "my-fck-nat"

  # use_cloudwatch_agent = true                 # Enables Cloudwatch agent and have metrics reported
}
```
