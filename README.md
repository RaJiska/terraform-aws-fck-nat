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

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.61.0 |
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | 2.4.0 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_iam_instance_profile.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.jumpbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_launch_template.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_network_interface.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_route.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.main_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.jumpbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ssm_parameter.cloudwatch_agent_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [time_sleep.wait_for_iam](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_ami.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_arn.ssm_param](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_default_tags.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_iam_policy_document.instance_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [cloudinit_config.this](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | A list of identifiers of security groups to be added for the NAT instance | `list(string)` | `[]` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI to use for the NAT instance. Uses fck-nat latest AMI in the region if none provided | `string` | `null` | no |
| <a name="input_attach_ssm_policy"></a> [attach\_ssm\_policy](#input\_attach\_ssm\_policy) | Whether to attach the minimum required IAM permissions to connect to the instance via SSM. | `bool` | `true` | no |
| <a name="input_auto_rollout"></a> [auto\_rollout](#input\_auto\_rollout) | Whether to automatically rollout configuration changes to the launch template (like AMI and cloud init) | `bool` | `false` | no |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | the CIDR block for VPC to use | `string` | `"10.123.0.0/16"` | no |
| <a name="input_cloud_init_parts"></a> [cloud\_init\_parts](#input\_cloud\_init\_parts) | Cloud-init parts to add to the user data script | <pre>list(object({<br>    content      = string<br>    content_type = string<br>  }))</pre> | `[]` | no |
| <a name="input_cloudwatch_agent_configuration"></a> [cloudwatch\_agent\_configuration](#input\_cloudwatch\_agent\_configuration) | CloudWatch configuration for the NAT instance | <pre>object({<br>    namespace           = optional(string, "fck-nat"),<br>    collection_interval = optional(number, 60),<br>    endpoint_override   = optional(string, "")<br>  })</pre> | <pre>{<br>  "collection_interval": 60,<br>  "endpoint_override": "",<br>  "namespace": "fck-nat"<br>}</pre> | no |
| <a name="input_cloudwatch_agent_configuration_param_arn"></a> [cloudwatch\_agent\_configuration\_param\_arn](#input\_cloudwatch\_agent\_configuration\_param\_arn) | ARN of the SSM parameter containing the CloudWatch agent configuration. If none provided, creates one | `string` | `null` | no |
| <a name="input_credit_specification"></a> [credit\_specification](#input\_credit\_specification) | Customize the credit specification of the instance | `string` | `null` | no |
| <a name="input_ebs_root_volume_size"></a> [ebs\_root\_volume\_size](#input\_ebs\_root\_volume\_size) | Size of the EBS root volume in GB | `number` | `8` | no |
| <a name="input_eip_allocation_ids"></a> [eip\_allocation\_ids](#input\_eip\_allocation\_ids) | EIP allocation IDs to use for the NAT instance. Automatically assign a public IP if none is provided. Note: Currently only supports at most one EIP allocation. | `list(string)` | `[]` | no |
| <a name="input_enable_jumpbox_instance"></a> [enable\_jumpbox\_instance](#input\_enable\_jumpbox\_instance) | Creates jumpbox instance to access resources in the VPC (SSM only) | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | n/a | yes |
| <a name="input_ha_additional_instance_types"></a> [ha\_additional\_instance\_types](#input\_ha\_additional\_instance\_types) | List of additional instance types to pass to the ASG, helpful when using spot instances with low availabiltiy | `list(string)` | `[]` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type to use for the NAT instance | `string` | `"t4g.micro"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Will use the provided KMS key ID to encrypt the EBS volume. Uses the default KMS key if none provided | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used for resources created within the module | `string` | n/a | yes |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | ARN of the IAM policy to use as a permissions boundary for the NAT instance IAM role | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Region in which to create resources, defaults to provider region if not set | `string` | `null` | no |
| <a name="input_use_cloudwatch_agent"></a> [use\_cloudwatch\_agent](#input\_use\_cloudwatch\_agent) | Whether or not to enable CloudWatch agent for the NAT instance | `bool` | `false` | no |
| <a name="input_use_default_security_group"></a> [use\_default\_security\_group](#input\_use\_default\_security\_group) | Whether or not to use the default security group for the NAT instance | `bool` | `true` | no |
| <a name="input_use_nat64"></a> [use\_nat64](#input\_use\_nat64) | Whether or not to enable NAT64 on the NAT instance. Your VPC and at least the public subnet this NAT instance is deployed into must support IPv6 | `bool` | `false` | no |
| <a name="input_use_spot_instances"></a> [use\_spot\_instances](#input\_use\_spot\_instances) | Whether or not to use spot instances for running the NAT instance | `bool` | `false` | no |

## Outputs

No outputs.
