resource "aws_autoscaling_group" "main" {
  count = var.ha_mode ? 1 : 0

  name                = var.name
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  health_check_type   = "EC2"
  vpc_zone_identifier = [var.subnet_id]

  capacity_rebalance = var.use_spot_instances

  mixed_instances_policy {
    instances_distribution {
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

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_lifecycle_hook" "spot_termination_wait" {
  count = var.ha_mode && var.use_spot_instances ? 1 : 0

  name                   = "TerminationWait"
  autoscaling_group_name = aws_autoscaling_group.main[0].name
  heartbeat_timeout      = 300
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}
