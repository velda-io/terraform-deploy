locals {
  agent_cidrs = var.gke_cluster != null ? [var.gke_cluster.cluster_ipv4_cidr] : ["*"]
}

data "aws_ami" "ubuntu24" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_subnet" "subnetwork" {
  id = var.subnet_ids[0]
}

resource "aws_instance" "controller" {
  ami                         = data.aws_ami.ubuntu24.id
  instance_type               = var.controller_machine_type
  subnet_id                   = var.subnet_ids[0]
  associate_public_ip_address = local.allow_public_access

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_size = var.data_disk_size
    volume_type = var.data_disk_type
    tags = {
      Name = "${var.name}-data"
    }
  }

  iam_instance_profile   = aws_iam_instance_profile.controller_profile.name
  vpc_security_group_ids = [aws_security_group.controller_sg.id]

  tags = {
    Name = var.name
  }

  user_data = templatefile("${path.module}/data/always_run.txt", {
    script = templatefile("${path.module}/data/controller_start.sh", {
      domain   = var.domain,
      instance = var.name,
      //gke_auth = var.gke_cluster != null ? "gcloud container clusters get-credentials ${var.gke_cluster.cluster_id} --location ${var.gke_cluster.location}  --project ${var.gke_cluster.project}" : ""
    })
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "lb" {
  instance = aws_instance.controller.id
  domain   = "vpc"
}

resource "aws_iam_instance_profile" "controller_profile" {
  name = "${var.name}-controller-profile"
  role = aws_iam_role.controller_role.name
}
