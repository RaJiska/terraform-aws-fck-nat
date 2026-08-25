data "cloudinit_config" "this" {
  for_each = local.private_az_subnets

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/user_data.sh", {
      TERRAFORM_ENI_ID                 = aws_network_interface.main[each.key].id
      TERRAFORM_EIP_ID                 = length(var.eip_allocation_ids) != 0 ? var.eip_allocation_ids[0] : ""
      TERRAFORM_CWAGENT_ENABLED        = var.use_cloudwatch_agent ? "true" : ""
      TERRAFORM_CWAGENT_CFG_PARAM_NAME = local.cwagent_param_name != null ? local.cwagent_param_name : ""
    })
  }

  dynamic "part" {
    for_each = var.cloud_init_parts

    content {
      content_type = part.value["content_type"]
      content      = part.value["content"]
    }
  }
}

resource "aws_launch_template" "main" {
  for_each = local.private_az_subnets

  #checkov:skip=CKV_AWS_88:NAT instances must have a public IP.
  region = var.region

  name          = "${var.name}-${each.key}"
  image_id      = local.ami_id
  instance_type = var.instance_type

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.ebs_root_volume_size
      volume_type = "gp3"
      encrypted   = true
      kms_key_id  = var.kms_key_id
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  network_interfaces {
    description                 = "${var.name} ephemeral public ENI"
    associate_public_ip_address = true
    security_groups             = local.security_groups
    ipv6_address_count          = var.use_nat64 ? 1 : null
  }

  dynamic "tag_specifications" {
    for_each = ["instance", "network-interface", "volume"]

    content {
      resource_type = tag_specifications.value

      tags = merge(data.aws_default_tags.current.tags, { Name = "${var.name}-${each.key}" }, var.tags)
    }
  }

  user_data = data.cloudinit_config.this[each.key].rendered

  credit_specification {
    cpu_credits = var.credit_specification
  }

  # Enforce IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = local.common_tags
}
