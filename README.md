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

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_iam_instance_profile.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_launch_template.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_network_interface.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_route.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ssm_parameter.cloudwatch_agent_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ami.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_arn.ssm_param](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.instance_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | A list of identifiers of security groups to be added for the NAT instance | `list(string)` | `[]` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI to use for the NAT instance. Uses fck-nat latest AMI in the region if none provided | `string` | `null` | no |
| <a name="input_attach_ssm_policy"></a> [attach\_ssm\_policy](#input\_attach\_ssm\_policy) | Whether to attach the minimum required IAM permissions to connect to the instance via SSM. | `bool` | `true` | no |
| <a name="input_cloudwatch_agent_configuration"></a> [cloudwatch\_agent\_configuration](#input\_cloudwatch\_agent\_configuration) | CloudWatch configuration for the NAT instance | <pre>object({<br/>    namespace           = optional(string, "fck-nat"),<br/>    collection_interval = optional(number, 60),<br/>    endpoint_override   = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "collection_interval": 60,<br/>  "endpoint_override": "",<br/>  "namespace": "fck-nat"<br/>}</pre> | no |
| <a name="input_cloudwatch_agent_configuration_param_arn"></a> [cloudwatch\_agent\_configuration\_param\_arn](#input\_cloudwatch\_agent\_configuration\_param\_arn) | ARN of the SSM parameter containing the CloudWatch agent configuration. If none provided, creates one | `string` | `null` | no |
| <a name="input_ebs_root_volume_size"></a> [ebs\_root\_volume\_size](#input\_ebs\_root\_volume\_size) | Size of the EBS root volume in GB | `number` | `8` | no |
| <a name="input_eip_allocation_ids"></a> [eip\_allocation\_ids](#input\_eip\_allocation\_ids) | EIP allocation IDs to use for the NAT instance. Automatically assign a public IP if none is provided. Note: Currently only supports at most one EIP allocation. | `list(string)` | `[]` | no |
| <a name="input_encryption"></a> [encryption](#input\_encryption) | Whether or not to encrypt the EBS volume | `bool` | `true` | no |
| <a name="input_ha_mode"></a> [ha\_mode](#input\_ha\_mode) | Whether or not high-availability mode should be enabled via autoscaling group | `bool` | `true` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type to use for the NAT instance | `string` | `"t4g.micro"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Will use the provided KMS key ID to encrypt the EBS volume. Uses the default KMS key if none provided | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used for resources created within the module | `string` | n/a | yes |
| <a name="input_route_table_id"></a> [route\_table\_id](#input\_route\_table\_id) | Deprecated. Use route\_tables\_ids instead | `string` | `null` | no |
| <a name="input_route_tables_ids"></a> [route\_tables\_ids](#input\_route\_tables\_ids) | Route tables to update. Only valid if update\_route\_tables is true | `map(string)` | `{}` | no |
| <a name="input_ssh_cidr_blocks"></a> [ssh\_cidr\_blocks](#input\_ssh\_cidr\_blocks) | CIDR blocks to allow SSH access to the NAT instance from | <pre>object({<br/>    ipv4 = optional(list(string), [])<br/>    ipv6 = optional(list(string), [])<br/>  })</pre> | <pre>{<br/>  "ipv4": [],<br/>  "ipv6": []<br/>}</pre> | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key to use for the NAT instance. SSH access will be enabled only if a key name is provided | `string` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID to deploy the NAT instance into | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources created within the module | `map(string)` | `{}` | no |
| <a name="input_update_route_table"></a> [update\_route\_table](#input\_update\_route\_table) | Deprecated. Use update\_route\_tables instead | `bool` | `false` | no |
| <a name="input_update_route_tables"></a> [update\_route\_tables](#input\_update\_route\_tables) | Whether or not to update the route tables with the NAT instance | `bool` | `false` | no |
| <a name="input_use_cloudwatch_agent"></a> [use\_cloudwatch\_agent](#input\_use\_cloudwatch\_agent) | Whether or not to enable CloudWatch agent for the NAT instance | `bool` | `false` | no |
| <a name="input_use_default_security_group"></a> [use\_default\_security\_group](#input\_use\_default\_security\_group) | Whether or not to use the default security group for the NAT instance | `bool` | `true` | no |
| <a name="input_use_spot_instances"></a> [use\_spot\_instances](#input\_use\_spot\_instances) | Whether or not to use spot instances for running the NAT instance | `bool` | `false` | no |
| <a name="input_use_ssh"></a> [use\_ssh](#input\_use\_ssh) | Whether or not to enable SSH access to the NAT instance | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID to deploy the NAT instance into | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ami_id"></a> [ami\_id](#output\_ami\_id) | AMI to use for the NAT instance. Uses fck-nat latest arm64 AMI in the region if none provided |
| <a name="output_autoscaling_group_arn"></a> [autoscaling\_group\_arn](#output\_autoscaling\_group\_arn) | The ARN of the autoscaling group if running in HA mode |
| <a name="output_cw_agent_config_ssm_parameter_arn"></a> [cw\_agent\_config\_ssm\_parameter\_arn](#output\_cw\_agent\_config\_ssm\_parameter\_arn) | The ARN of the SSM parameter containing the Cloudwatch agent config |
| <a name="output_encryption"></a> [encryption](#output\_encryption) | Whether or not fck-nat instance EBS volumes are encrypted |
| <a name="output_eni_arn"></a> [eni\_arn](#output\_eni\_arn) | The ARN of the static ENI used by the fck-nat instance |
| <a name="output_eni_id"></a> [eni\_id](#output\_eni\_id) | The ID of the static ENI used by the fck-nat instance |
| <a name="output_ha_mode"></a> [ha\_mode](#output\_ha\_mode) | Whether or not high-availability mode is enabled via autoscaling group |
| <a name="output_instance_arn"></a> [instance\_arn](#output\_instance\_arn) | The ARN of the fck-nat instance if running in non-HA mode |
| <a name="output_instance_profile_arn"></a> [instance\_profile\_arn](#output\_instance\_profile\_arn) | The ARN of the instance profile used by the fck-nat instance |
| <a name="output_instance_public_ip"></a> [instance\_public\_ip](#output\_instance\_public\_ip) | The public IP address of the fck-nat instance if running in non-HA mode |
| <a name="output_instance_type"></a> [instance\_type](#output\_instance\_type) | Instance type used for the fck-nat instance |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | KMS key ID to use for encrypting fck-nat instance EBS volumes |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | The ID of the launch template used to spawn fck-nat instances |
| <a name="output_name"></a> [name](#output\_name) | Name used for resources created within the module |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | The ARN of the role used by the fck-nat instance profile |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Deprecated. The ID of the security group used by fck-nat ENIs |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | List of security group IDs used by fck-nat ENIs |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | Subnet ID to which the fck-nat instance is deployed into |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID to which the fck-nat instance is deployed into |