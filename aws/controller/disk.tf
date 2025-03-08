/*
resource "aws_ebs_volume" "disk_volume" {
  availability_zone = var.zone
  size              = var.data_disk_size
  type              = var.data_disk_type
  tags = {
    Name = "${var.name}-data"
  }
}

*/