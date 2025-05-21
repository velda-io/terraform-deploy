resource "google_compute_firewall" "allow_api_port" {
  name    = "${var.name}-api-access"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "2222"]
  }

  source_ranges = var.external_access.allowed_source_ranges
  source_tags   = var.external_access.allowed_source_tags
  target_tags   = ["${var.name}-server"]
}

resource "google_compute_firewall" "agent_access" {
  name    = "${var.name}-agent-access"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "2222", "50051", "2049"]
  }

  source_tags   = ["${var.name}-agent"]
  target_tags   = ["${var.name}-server"]
}