resource "aws_autoscaling_group" "main" {
  count = var.ha_mode ? 1 : 0

  name                = var.name
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  health_check_type   = "EC2"
  vpc_zone_identifier = [var.subnet_id]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
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
