locals {
  # AZs actually used for subnets in vpc.tf
  asg_azs = slice(data.aws_availability_zones.available.names, 0, length(aws_subnet.public))

  # Public subnets (for ASG/instance placement), keyed by AZ
  asg_az_subnets = { for idx, az in local.asg_azs : az => aws_subnet.public[idx].id }

  # Private subnets and their route tables (for the static internal ENI), keyed by AZ
  private_az_subnets      = { for idx, az in local.asg_azs : az => aws_subnet.private[idx].id }
  private_az_route_tables = { for idx, az in local.asg_azs : az => aws_route_table.private[idx].id }
}

resource "aws_autoscaling_group" "main" {
  for_each = local.asg_az_subnets

  region = var.region

  name                = "${var.name}-${each.key}"
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
        launch_template_id = aws_launch_template.main[each.key].id
        version            = aws_launch_template.main[each.key].latest_version
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
    for_each = local.common_tags

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
    "WarmPoolDesiredCapacity",
    "WarmPoolWarmedCapacity",
    "WarmPoolPendingCapacity",
    "WarmPoolTerminatingCapacity",
    "WarmPoolTotalCapacity",
    "GroupAndWarmPoolDesiredCapacity",
    "GroupAndWarmPoolTotalCapacity"
  ]

  timeouts {
    delete = "15m"
  }
}
