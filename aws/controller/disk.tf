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