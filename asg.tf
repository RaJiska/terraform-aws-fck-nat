resource "aws_autoscaling_group" "main" {
  count = var.ha_mode ? 1 : 0

  region = var.region

  name                = var.name
  max_size            = 1
  min_size            = var.min_size
  desired_capacity    = 1
  health_check_type   = "EC2"
  vpc_zone_identifier = [var.subnet_id]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = var.use_spot_instances ? 0 : 100
      spot_allocation_strategy                 = "price-capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.main.id
        version            = aws_launch_template.main.latest_version
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
    for_each = var.tags

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
