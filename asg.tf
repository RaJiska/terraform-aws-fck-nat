resource "aws_autoscaling_group" "main" {
  count = var.ha_mode ? 1 : 0

  name                = var.name
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  health_check_type   = "EC2"
  vpc_zone_identifier = [var.subnet_id]
  capacity_rebalance  = var.use_spot_instances && length(var.instance_types) > 1 ? true : false

  dynamic "mixed_instances_policy" {
    for_each = length(var.instance_types) > 0 ? [1] : []
    content {
      instances_distribution {
        on_demand_base_capacity                  = var.use_spot_instances ? 0 : 1
        on_demand_percentage_above_base_capacity = var.use_spot_instances ? 0 : 100
        spot_allocation_strategy                 = "price-capacity-optimized"
      }

      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.main.id
          version            = "$Latest"
        }

        dynamic "override" {
          for_each = var.instance_types
          content {
            instance_type = override.value
          }
        }
      }
    }
  }

  dynamic "tag" {
    for_each = lookup(var.tags, "Name", null) == null ? ["Name"] : []

    content {
      key                 = "Name"
      value               = var.name
      propagate_at_launch = true
    }
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
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
