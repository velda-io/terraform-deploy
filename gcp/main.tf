terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.15.0"
    }
    terraform = {
      source = "terraform.io/builtin/terraform"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}
data "google_project" "project" {
  project_id = var.project
}

locals {
  network_component    = regex("^projects/([^/]+)/global/networks/(.+)$", var.network)
  subnetwork_component = regex("^projects/([^/]+)/regions/([^/]+)/subnetworks/(.+)$", var.subnetwork)
}

data "google_compute_subnetwork" "subnetwork" {
  project = local.subnetwork_component[0]
  region  = local.subnetwork_component[1]
  name    = local.subnetwork_component[2]
}

resource "google_service_account" "controller_sa" {
  project      = var.project
  account_id   = "${var.name}-controller"
  display_name = "Controller Service Account"
}

resource "google_service_account" "agent_sa" {
  project      = var.project
  account_id   = "${var.name}-agent"
  display_name = "agent Service Account"
}

locals {
  permission_request = jsonencode({
    controller_sa = google_service_account.controller_sa.email
    agent_sa      = google_service_account.agent_sa.email
    project_id    = data.google_project.project.project_id
  })
}

resource "null_resource" "update_sa_permissions" {
  triggers = {
    controller_sa  = google_service_account.controller_sa.email
    agent_sa       = google_service_account.agent_sa.email
    project_id     = data.google_project.project.project_id
    access_granted = var.access_granted
  }

  provisioner "local-exec" {
    command = <<EOT
      ${var.access_granted ? "exit 0" : ""}
echo "Please provide the following info to Velda Inc:"
echo "${local.permission_request}"
echo "After granting the permissions, add "access_granted = true" to variables and run 'terraform apply' again."
exit 1
EOT
  }
}

module "controller" {
  depends_on = [null_resource.update_sa_permissions]
  source     = "./controller"
  providers = {
    google = google
  }

  project    = var.project
  region     = var.region
  zone       = var.zone
  subnetwork = var.subnetwork
  network    = var.network
  domain     = var.domain

  controller_image = var.controller_image

  external_access = var.external_access
  use_nat_gateway = var.external_access.use_nat_gateway

  configs    = var.configs
  agent_cidr = [data.google_compute_subnetwork.subnetwork.ip_cidr_range]

  https_certs = var.https_certs == null ? null : {
    cert = file(var.https_certs.cert)
    key  = file(var.https_certs.key)
  }

  base_instance_images = var.base_instance_images

  enable_saml = lookup(var.configs, "enable_saml", false)
}

module "agent" {
  source   = "./agent"
  for_each = { for pool in var.gce_pools : pool.name => pool }

  controller_output = module.controller.agent_configs

  pool             = each.value.name
  instance_type    = each.value.machine_type
  agent_image      = each.value.image != null ? each.value.image : var.agent_image_version[each.value.image_type]
  autoscale_config = each.value.autoscale_config

  accelerator_count = each.value.accelerator_count
  accelerator_type  = each.value.accelerator_type

  sandbox_config = each.value.sandbox_config
  daemon_config  = each.value.daemon_config
}
