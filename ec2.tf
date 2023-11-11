data "aws_ami" "main" {
  count = var.ami_id != null ? 0 : 1

  most_recent = true
  owners      = ["568608671756"]

  filter {
    name   = "name"
    values = ["fck-nat-amzn2-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = [local.is_arm ? "arm64" : "x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "main" {
  name          = var.name
  image_id      = local.ami_id
  instance_type = var.instance_type

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.ebs_root_volume_size
      volume_type = "gp3"
      encrypted   = var.encryption
      kms_key_id  = var.kms_key_id
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  network_interfaces {
    description                 = "${var.name} ephemeral public ENI"
    subnet_id                   = var.subnet_id
    associate_public_ip_address = true
    security_groups             = [aws_security_group.main.id]
  }

  dynamic "instance_market_options" {
    for_each = var.use_spot_instances ? ["x"] : []

    content {
      market_type = "spot"
    }
  }

  dynamic "tag_specifications" {
    for_each = ["instance", "network-interface", "volume"]

    content {
      resource_type = tag_specifications.value

      tags = merge(var.tags, {
        Name = var.name
      })
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    TERRAFORM_ENI_ID                = aws_network_interface.main.id
    TERRAFORM_EIP_ID                = length(var.eip_allocation_ids) != 0 ? var.eip_allocation_ids[0] : ""
    TERRAFORM_CWAGENT_ENABLED       = var.use_cloudwatch_agent ? "true" : ""
    TERRAFORM_CWAGENT_CFG_PARAM_ARN = var.use_cloudwatch_agent ? aws_ssm_parameter.cloudwatch_agent_config[0].arn : ""
  }))

  tags = var.tags
}

resource "aws_instance" "main" {
  count = var.ha_mode ? 0 : 1

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      source_dest_check,
      user_data,
      tags
    ]
  }
}
