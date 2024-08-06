# AllAZs Example

To avoid cross-AZ [data transfer charges](https://aws.amazon.com/ec2/pricing/on-demand/#Data_Transfer_within_the_same_AWS_Region), provide greater [bandwidth](https://fck-nat.dev/stable/choosing_an_instance_size/), and reduce cross-AZ [dependencies](https://docs.aws.amazon.com/whitepapers/latest/aws-fault-isolation-boundaries/zonal-services.html), this example creates a fck-nat instance in each public subnet, and manages the routing table in each AZ's private subnet to use the fck-nat instance in that AZ's public subnet.

This example creates infrastructure from scratch (VPC, public and private subnets in each AZ, IGW) to work and test this Terraform module. In a real
scenario, you will most probably already have those resources and therefore should only have to focus on calling the
fck-nat module as done in the [main.tf](main.tf) example source file.

## Usage

To run this example you need to execute:
```
$ terraform init
$ terraform plan
$ terraform apply
```
