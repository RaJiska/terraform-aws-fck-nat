output "name" {
  description = "Name used for resources created within the module"
  value       = var.name
}

output "vpc_id" {
  description = "VPC ID to which the fck-nat instance is deployed into"
  value       = var.vpc_id
}

output "subnet_id" {
  description = "Subnet ID to which the fck-nat instance is deployed into"
  value       = var.subnet_id
}

output "encryption" {
  description = "Whether or not fck-nat instance EBS volumes are encrypted"
  value       = var.encryption
}

output "kms_key_id" {
  description = "KMS key ID to use for encrypting fck-nat instance EBS volumes"
  value       = var.kms_key_id
}

output "ha_mode" {
  description = "Whether or not high-availability mode is enabled via autoscaling group"
  value       = var.ha_mode
}

output "instance_type" {
  description = "Instance type used for the fck-nat instance"
  value       = aws_launch_template.main.instance_type
}

output "ami_id" {
  description = "AMI to use for the NAT instance. Uses fck-nat latest arm64 AMI in the region if none provided"
  value       = aws_launch_template.main.image_id
}

output "eni_id" {
  description = "The ID of the static ENI used by the fck-nat instance"
  value       = aws_network_interface.main.id
}

output "eni_arn" {
  description = "The ARN of the static ENI used by the fck-nat instance"
  value       = aws_network_interface.main.arn
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

output "instance_profile_arn" {
  description = "The ARN of the instance profile used by the fck-nat instance"
  value       = aws_iam_instance_profile.main.arn
}

output "launch_template_id" {
  description = "The ID of the launch template used to spawn fck-nat instances"
  value       = aws_launch_template.main.arn
}

output "instance_arn" {
  description = "The ARN of the fck-nat instance if running in non-HA mode"
  value       = var.ha_mode ? null : aws_instance.main[0].arn
}

output "instance_public_ip" {
  description = "The public IP address of the fck-nat instance if running in non-HA mode"
  value       = var.ha_mode ? null : aws_instance.main[0].public_ip
}

output "autoscaling_group_arn" {
  description = "The ARN of the autoscaling group if running in HA mode"
  value       = var.ha_mode ? aws_autoscaling_group.main[0].arn : null
}

output "cw_agent_config_ssm_parameter_arn" {
  description = "The ARN of the SSM parameter containing the Cloudwatch agent config"
  value       = local.cwagent_param_arn
}