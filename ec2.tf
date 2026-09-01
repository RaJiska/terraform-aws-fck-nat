resource "aws_security_group" "nat_instance" {
  #checkov:skip=CKV_AWS_24:False positive, ingress CIDR blocks on port 22 default to "[]"
  #checkov:skip=CKV_AWS_382:Security group is used for NAT instance, intended to egress to the world
  # Region is determined by the configured AWS provider

  name        = local.name
  description = "Used in ${local.name} instances of fck-nat"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "Unrestricted ingress from within VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.main.cidr_block]
    ipv6_cidr_blocks = var.use_nat64 ? [aws_vpc.main.ipv6_cidr_block] : null
  }

  egress {
    description      = "Unrestricted egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, { Name = local.name })
}


data "cloudinit_config" "nat_instance" {
  for_each = local.private_az_subnets

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/user_data.sh", {
      TERRAFORM_ENI_ID                 = aws_network_interface.main[each.key].id
      TERRAFORM_EIP_ID                 = lookup(var.eip_allocation_ids, each.key, "")
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

resource "aws_launch_template" "nat_instance" {
  for_each = local.private_az_subnets

  #checkov:skip=CKV_AWS_88:NAT instances must have a public IP.
  region = local.region

  name          = "${local.name}-${each.key}"
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
    name = aws_iam_instance_profile.nat_instance.name
  }

  network_interfaces {
    description                 = "${local.name}-${each.key} ephemeral public ENI"
    associate_public_ip_address = true
    security_groups             = local.security_groups
    ipv6_address_count          = var.use_nat64 ? 1 : null
  }

  dynamic "tag_specifications" {
    for_each = ["instance", "network-interface", "volume"]

    content {
      resource_type = tag_specifications.value

      tags = merge(local.common_tags, { Name = "${local.name}-${each.key}" })
    }
  }

  user_data = data.cloudinit_config.nat_instance[each.key].rendered

  credit_specification {
    cpu_credits = var.credit_specification
  }

  # Enforce IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.common_tags, { Name = "${local.name}-${each.key}" })
}




#######
# ASG #
#######

# Needed to ensure the IAM instance profile is fully propagated before creating the ASG
resource "time_sleep" "wait_for_iam" {
  depends_on      = [aws_iam_instance_profile.nat_instance]
  create_duration = "15s"
}


resource "aws_autoscaling_group" "nat_instance" {
  for_each = local.asg_az_subnets

  region = local.region

  name                = "${local.name}-${each.key}"
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  health_check_type   = "EC2"
  vpc_zone_identifier = [each.value]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = var.use_spot_instances ? 0 : 100
      spot_allocation_strategy                 = "price-capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.nat_instance[each.key].id
        version            = aws_launch_template.nat_instance[each.key].latest_version
      }

      override {
        instance_type = var.instance_type
      }

      dynamic "override" {
        for_each = toset(var.ha_additional_instance_types)

        content {
          instance_type = override.value
        }
      }
    }
  }

  dynamic "tag" {
    for_each = merge(local.common_tags, { "Name" = "${local.name}-${each.key}" })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  dynamic "instance_refresh" {
    for_each = var.auto_rollout ? [true] : []
    content {
      strategy = "Rolling"
      preferences {
        # network interface needs to be freed, before it can be attached to a new instance
        min_healthy_percentage = 0
      }
    }
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTotalCapacity",
  ]

  timeouts {
    delete = "15m"
  }

  depends_on = [time_sleep.wait_for_iam]
}
