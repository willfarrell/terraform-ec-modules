resource "aws_launch_template" "main" {
  name                   = local.name
  image_id               = local.image_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  ebs_optimized          = false
  update_default_version = true
  user_data              = base64encode(local.user_data)

  dynamic "instance_market_options" {
    for_each = var.spot ? [true] : []
    content {
      market_type = "spot"

      spot_options {
        spot_instance_type = "one-time"
      }
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.volume_size == 0 ? [] : [true]
    content {
      device_name = data.aws_ami.main.root_device_name

      ebs {
        volume_type           = var.volume_type
        volume_size           = var.volume_size
        delete_on_termination = true
        encrypted             = true
      }
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.main.arn
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    # Must be true in public subnets if assigning EIP in userdata
    associate_public_ip_address = var.subnet_public
    delete_on_termination       = true
    security_groups             = [aws_security_group.main.id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }
}

resource "aws_autoscaling_group" "main" {
  name                      = "${local.name}-asg"
  max_size                  = local.max_size
  min_size                  = local.min_size
  desired_capacity          = local.desired_capacity
  health_check_grace_period = 30
  vpc_zone_identifier       = var.subnet_ids

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.tags
    content {
      key   = tag.key
      value = tag.value

      propagate_at_launch = true
    }
  }
}

// Schedules
resource "aws_autoscaling_schedule" "scale_up" {
  count                  = var.schedule_scale_up_recurrence != "" ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.main.name
  scheduled_action_name  = "ScaleUp"
  min_size               = local.min_size
  max_size               = local.max_size
  desired_capacity       = local.desired_capacity
  recurrence             = var.schedule_scale_up_recurrence
}

resource "aws_autoscaling_schedule" "scale_down" {
  count                  = var.schedule_scale_down_recurrence != "" ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.main.name
  scheduled_action_name  = "ScaleDown"
  min_size               = local.min_size
  max_size               = local.max_size
  desired_capacity       = 0
  recurrence             = var.schedule_scale_down_recurrence
}

resource "aws_autoscaling_schedule" "shut_down" {
  count                  = var.schedule_shut_down_recurrence != "" ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.main.name
  scheduled_action_name  = "ShutDown"
  min_size               = 0
  max_size               = 1
  desired_capacity       = 0
  recurrence             = var.schedule_shut_down_recurrence
}
