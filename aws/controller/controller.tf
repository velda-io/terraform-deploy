locals {
  agent_cidrs = var.gke_cluster != null ? [var.gke_cluster.cluster_ipv4_cidr] : ["*"]
}

data "aws_subnet" "subnetwork" {
  id = var.subnet_ids[0]
}

resource "null_resource" "check_permissions" {
  triggers = {
    bin_authorized = var.bin_authorized
  }
  provisioner "local-exec" {
    command = <<EOT
${var.bin_authorized ? "exit 0" : "exit 1"}
EOT
  }
}

resource "aws_ebs_volume" "controller_data" {
  availability_zone = data.aws_subnet.subnetwork.availability_zone
  size              = var.data_disk_size
  type              = var.data_disk_type
  tags = {
    Name = "${var.name}-data"
  }
}

resource "aws_volume_attachment" "controller_data_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.controller_data.id
  instance_id = aws_instance.controller.id
}

resource "aws_instance" "controller" {
  depends_on                  = [null_resource.check_permissions, aws_db_instance.postgres_instance]
  ami                         = var.controller_ami
  instance_type               = var.controller_machine_type
  subnet_id                   = var.controller_subnet_id
  associate_public_ip_address = var.external_access.use_controller_external_ip || var.external_access.use_eip

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }


  iam_instance_profile   = aws_iam_instance_profile.controller_profile.name
  vpc_security_group_ids = [aws_security_group.controller_sg.id]

  tags = {
    Name = var.name
  }

  user_data = var.controller_ami != null ? base64encode(<<EOF
#!/bin/bash
cat << EOT > /tmp/velda_install.json
${jsonencode({
    "instance_id" : var.name,
    "base_instance_images" : var.base_instance_images,
    "zfs_disks" : ["/dev/xvdf"],
})}
EOT
/opt/velda/bin/setup.sh /tmp/velda_install.json
EOF
) : templatefile("${path.module}/data/always_run.txt", {
  script = templatefile("${path.module}/data/controller_start.sh", {
    instance = var.name,
  })
}
)

lifecycle {
  create_before_destroy = true
}
}

resource "aws_eip" "lb" {
  count    = var.external_access.use_eip ? 1 : 0
  instance = aws_instance.controller.id
  domain   = "vpc"
}

resource "aws_iam_instance_profile" "controller_profile" {
  name = "${var.name}-controller-profile"
  role = aws_iam_role.controller_role.name
}
