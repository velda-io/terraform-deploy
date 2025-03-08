resource "google_project_service" "apis" {
  project            = var.project
  for_each           = toset(["servicenetworking.googleapis.com", "compute.googleapis.com", "container.googleapis.com", "secretmanager.googleapis.com"])
  service            = each.key
  disable_on_destroy = false
}