resource "aws_launch_template" "agent" {
  name   = "${var.controller_output.name}-agent-${var.pool}"
  image_id      = var.agent_ami
  instance_type = var.instance_type

  network_interfaces {
    subnet_id                   = var.controller_output.subnet_ids[0]
    associate_public_ip_address = true
    security_groups             = var.controller_output.security_group_ids
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8
      volume_type = "gp2"
    }
  }

  iam_instance_profile {
    name = var.controller_output.instance_profile
  }
  tags = {
    VeldaApp = var.controller_output.name
    Pool = var.pool
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      VeldaApp = var.controller_output.name
      Pool = var.pool
    }
  }
  update_default_version = true
}

