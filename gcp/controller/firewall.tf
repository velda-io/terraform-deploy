resource "google_compute_firewall" "allow_api_port" {
  count   = local.allow_public_access ? 1 : 0
  name    = "allow-custom-port"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["2222", "50051"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.name}-server"]
}
