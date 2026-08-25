output "name" {
  description = "Name used for resources created within the module"
  value       = var.name
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC created for the fck-nat instances"
  value       = aws_vpc.current.cidr_block
}

output "kms_key_id" {
  description = "KMS key ID to use for encrypting fck-nat instance EBS volumes"
  value       = var.kms_key_id
}

output "instance_type" {
  description = "Instance type used for the fck-nat instances"
  value       = var.instance_type
}

output "ha_additional_instance_types" {
  description = "List of additional instance types to pass to the ASG, helpful when using spot instances with low availabiltiy"
  value       = var.ha_additional_instance_types
}

output "ami_id" {
  description = "AMI used for the fck-nat instances"
  value       = local.ami_id
}

output "eni_ids" {
  description = "Map of AZ to the ID of the static ENI used by the fck-nat instance in that AZ"
  value       = { for az, eni in aws_network_interface.main : az => eni.id }
}

output "eni_arns" {
  description = "Map of AZ to the ARN of the static ENI used by the fck-nat instance in that AZ"
  value       = { for az, eni in aws_network_interface.main : az => eni.arn }
}

output "security_group_id" {
  description = "Deprecated. The ID of the security group used by fck-nat ENIs"
  value       = aws_security_group.main.id
}

output "security_group_ids" {
  description = "List of security group IDs used by fck-nat ENIs"
  value       = local.security_groups
}

output "role_arn" {
  description = "The ARN of the role used by the fck-nat instance profile"
  value       = aws_iam_role.main.arn
}

output "role_name" {
  description = "The ARN of the role used by the fck-nat instance profile"
  value       = aws_iam_role.main.name
}

output "instance_profile_arn" {
  description = "The ARN of the instance profile used by the fck-nat instance"
  value       = aws_iam_instance_profile.main.arn
}

output "launch_template_ids" {
  description = "Map of AZ to the ID of the launch template used to spawn fck-nat instances in that AZ"
  value       = { for az, lt in aws_launch_template.main : az => lt.id }
}

output "autoscaling_group_arns" {
  description = "Map of AZ to the ARN of the autoscaling group running fck-nat instances in that AZ"
  value       = { for az, asg in aws_autoscaling_group.main : az => asg.arn }
}

output "autoscaling_group_names" {
  description = "Map of AZ to the name of the autoscaling group running fck-nat instances in that AZ"
  value       = { for az, asg in aws_autoscaling_group.main : az => asg.name }
}

output "cw_agent_config_ssm_parameter_arn" {
  description = "The ARN of the SSM parameter containing the Cloudwatch agent config"
  value       = local.cwagent_param_arn
}
