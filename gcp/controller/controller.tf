locals {
  allow_public_access = var.external_access != null
}
resource "google_compute_instance" "controller" {
  project = var.project

  name = var.name

  attached_disk {
    device_name = "zfs"
    mode        = "READ_WRITE"

    source = google_compute_disk.disk_volume.self_link
  }

  boot_disk {
    auto_delete = true
    device_name = "${var.name}-bootdisk"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2404-noble-amd64-v20241219"
      size  = 10
      type  = "pd-standard"
    }

    mode = "READ_WRITE"
  }
  machine_type = var.controller_machine_type

  network_interface {
    dynamic "access_config" {
      for_each = local.allow_public_access ? [1] : []
      content {
        network_tier = var.external_access.network_tier
        nat_ip       = var.external_access.ip_address
      }
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = var.subnetwork
  }

  scheduling {
    automatic_restart   = false
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }
  service_account {
    email = google_service_account.controller_sa.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  tags = concat([
    "http-server",
    "https-server",
    ],
    local.allow_public_access ? ["${var.name}-server"] : []
  )

  metadata = merge(
    {
      velda-instance = var.name
      # Use sensitive to reduce diff.
      auth-public-key  = sensitive(tls_private_key.auth_token_key.public_key_pem)
      auth-private-key = sensitive(tls_private_key.auth_token_key.private_key_pem)
      velda-domain     = var.domain
      ops-agent-config = file("${path.module}/data/ops_agent_config.yaml")
      startup-script   = file("${path.module}/data/controller_start.sh")
    },
    module.configs.configs,
    var.gke_cluster != null ? {
      gke-auth = "gcloud container clusters get-credentials ${var.gke_cluster.cluster_id} --location ${var.gke_cluster.location}  --project ${var.gke_cluster.project}"
  } : {})

  zone = var.zone

  lifecycle {
    ignore_changes = [metadata["ssh-keys"]]
  }
}
