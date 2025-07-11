locals {
  has_gpu = var.accelerator_type != null && var.accelerator_count > 0
}
resource "google_compute_instance_template" "agent_template" {
  name_prefix           = "${var.controller_output.name}-agent-${var.pool}-"
  machine_type   = var.instance_type
  can_ip_forward = false

  disk {
    source_image = var.agent_image
    auto_delete  = true
    disk_size_gb = 10
    disk_type    = "pd-standard"
    boot         = true
  }

  network_interface {
    network    = var.controller_output.network
    subnetwork = var.controller_output.subnetwork

    // Only allocate a public IP if the NAT gateway is not used
    dynamic "access_config" {
      for_each = var.controller_output.use_nat_gateway ? [] : [1]
      content {
        network_tier = "STANDARD"
      }
    }
  }

  dynamic "guest_accelerator" {
    for_each = local.has_gpu ? [1] : []
    content {
      type  = var.accelerator_type
      count = var.accelerator_count
    }
  }

  scheduling {
    on_host_maintenance = local.has_gpu ? "TERMINATE" : "MIGRATE"
  }

  service_account {
    email  = var.controller_output.agent_service_account
    scopes = ["cloud-platform"]
  }

  metadata = {
    velda_instance = var.controller_output.name
    pool           = var.pool
    velda_host     = var.controller_output.controller_ip
    velda_config = yamlencode({
      broker = {
        address = "http://${var.controller_output.controller_ip}:50051"
      }
    })
  }

  tags = ["${var.controller_output.name}-agent", "${var.pool}"]

  lifecycle {
    create_before_destroy = true
  }

}

resource "google_compute_instance_group_manager" "agent_group" {
  name               = "${var.controller_output.name}-agent-${var.pool}"
  base_instance_name = "${var.controller_output.name}-agent"
  zone               = var.controller_output.zone
  version {
    instance_template = google_compute_instance_template.agent_template.self_link
  }
}
