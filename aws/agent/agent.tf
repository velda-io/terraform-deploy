terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.87.0"
    }
  }
}

resource "aws_launch_template" "agent" {
  name          = "${var.controller_output.name}-agent-${var.pool}"
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
    Pool     = var.pool
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      VeldaApp = var.controller_output.name
      Pool     = var.pool
    }
  }
  update_default_version = true

  user_data = var.init_script_content != null ? base64encode(var.init_script_content) : null

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ssm_parameter" "agent_daemon_config" {
  name = "/${var.controller_output.name}/agent-config/${var.pool}"
  type = "String"
  value = yamlencode({
    broker = {
      address = "http://${var.controller_output.controller_ip}:50051"
    }
    daemon_config = var.daemon_config
    sandbox_config = var.sandbox_config
  })
}
