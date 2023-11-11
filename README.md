# Terraform fck-nat

A Terraform module for deploying NAT Instances using [fck-nat](https://github.com/AndrewGuenther/fck-nat). The (f)easible (c)ost (k)onfigurable NAT!

* Overpaying for AWS Managed NAT Gateways? fck-nat.
* Want to use NAT instances and stay up-to-date with the latest security patches? fck-nat.
* Want to reuse your Bastion hosts as a NAT? fck-nat.

fck-nat offers a ready-to-use ARM and x86 based AMIs built on Amazon Linux 2 which can support up to 5Gbps NAT traffic
on a t4g.nano instance. How does that compare to a Managed NAT Gateway?

Hourly rates:
* Managed NAT Gateway hourly: $0.045
* t4g.nano hourly: $0.0042

Per GB rates:
* Managed NAT Gateway per GB: $0.045
* fck-nat per GB: $0.00

Sitting idle, fck-nat costs 10% of a Managed NAT Gateway. In practice, the savings are even greater.

*"But what about AWS' NAT Instance AMI?"*

The official AWS supported NAT Instance AMI hasn't been updates since 2018, is still running Amazon Linux 1 which is
now EOL, and has no ARM support, meaning it can't be deployed on EC2's most cost effective instance types. fck-nat.

*"When would I want to use a Managed NAT Gateway instead of fck-nat?"*

AWS limits outgoing internet bandwidth on EC2 instances to 5Gbps. This means that the highest bandwidth that fck-nat
can support is 5Gbps. This is enough to cover a very broad set of use cases, but if you need additional bandwidth,
you should use Managed NAT Gateway. If AWS were to lift the limit on internet egress bandwidth from EC2, you could
cost-effectively operate fck-nat at speeds up to 25Gbps, but you wouldn't need Managed NAT Gateway then would you?
fck-nat.

Read more about EC2 bandwidth limits here: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-network-bandwidth.html

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_iam_instance_profile.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_instance.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_launch_template.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_network_interface.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_route.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI to use for the NAT instance. Uses fck-nat latest AMI in the region if none provided | `string` | `null` | no |
| <a name="input_ebs_root_volume_size"></a> [ebs\_root\_volume\_size](#input\_ebs\_root\_volume\_size) | Size of the EBS root volume in GB | `number` | `2` | no |
| <a name="input_eip_allocation_ids"></a> [eip\_allocation\_ids](#input\_eip\_allocation\_ids) | EIP allocation IDs to use for the NAT instance. Automatically assign a public IP if none is provided. Note: Currently only supports at most one EIP allocation. | `list(string)` | `[]` | no |
| <a name="input_encryption"></a> [encryption](#input\_encryption) | Whether or not to encrypt the EBS volume | `bool` | `true` | no |
| <a name="input_ha_mode"></a> [ha\_mode](#input\_ha\_mode) | Whether or not high-availability mode should be enabled via autoscaling group | `bool` | `true` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type to use for the NAT instance | `string` | `"t4g.micro"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Will use the provided KMS key ID to encrypt the EBS volume. Uses the default KMS key if none provided | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used for resources created within the module | `string` | n/a | yes |
| <a name="input_route_table_id"></a> [route\_table\_id](#input\_route\_table\_id) | Route table to update. Only valid if update\_route\_table is true | `string` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID to deploy the NAT instance into | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources created within the module | `map(string)` | `{}` | no |
| <a name="input_update_route_table"></a> [update\_route\_table](#input\_update\_route\_table) | Whether or not to update the route table with the NAT instance | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID to deploy the NAT instance into | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ami_id"></a> [ami\_id](#output\_ami\_id) | AMI to use for the NAT instance. Uses fck-nat latest arm64 AMI in the region if none provided |
| <a name="output_autoscaling_group_arn"></a> [autoscaling\_group\_arn](#output\_autoscaling\_group\_arn) | The ARN of the autoscaling group if running in HA mode |
| <a name="output_encryption"></a> [encryption](#output\_encryption) | Whether or not fck-nat instance EBS volumes are encrypted |
| <a name="output_eni_arn"></a> [eni\_arn](#output\_eni\_arn) | The ARN of the static ENI used by the fck-nat instance |
| <a name="output_eni_id"></a> [eni\_id](#output\_eni\_id) | The ID of the static ENI used by the fck-nat instance |
| <a name="output_ha_mode"></a> [ha\_mode](#output\_ha\_mode) | Whether or not high-availability mode is enabled via autoscaling group |
| <a name="output_instance_arn"></a> [instance\_arn](#output\_instance\_arn) | The ARN of the fck-nat instance if running in non-HA mode |
| <a name="output_instance_profile_arn"></a> [instance\_profile\_arn](#output\_instance\_profile\_arn) | The ARN of the instance profile used by the fck-nat instance |
| <a name="output_instance_type"></a> [instance\_type](#output\_instance\_type) | Instance type used for the fck-nat instance |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | KMS key ID to use for encrypting fck-nat instance EBS volumes |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | The ID of the launch template used to spawn fck-nat instances |
| <a name="output_name"></a> [name](#output\_name) | Name used for resources created within the module |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | The ARN of the role used by the fck-nat instance profile |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The ID of the security group used by fck-nat ENIs |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | Subnet ID to which the fck-nat instance is deployed into |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID to which the fck-nat instance is deployed into |
