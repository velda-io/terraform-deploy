
output "auth_public_key_secret" {
  value = google_secret_manager_secret.auth_public_key.id
}

output "agent_configs" {
  value = {
    project       = var.project
    name          = var.name
    region        = var.region
    zone          = var.zone
    network       = var.network
    subnetwork    = var.subnetwork
    controller_ip = google_compute_instance.controller.network_interface[0].network_ip

    agent_service_account = data.google_service_account.agent_sa.email
    has_external_ip      = !var.use_nat_gateway

    config_gcs_bucket = google_storage_bucket.pool_configs.name
    config_gcs_prefix = "pools/"
  }
}


output "controller" {
  value = {
    project = google_compute_instance.controller.project
    id      = google_compute_instance.controller.id
    name    = google_compute_instance.controller.name
    zone    = google_compute_instance.controller.zone
  }
}
