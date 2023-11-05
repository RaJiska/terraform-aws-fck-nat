# Full Example

This example creates infrastructure from scratch (VPC, subnets, igw) to work and test this Terraform module. In a real
scenario, you will most probably already have those resources and therefore should only have to focus on calling the
fck-nat module as done in the [main.tf](main.tf) example source file.

## Usage

To run this example you need to execute:
```
$ terraform init
$ terraform plan
$ terraform apply
```