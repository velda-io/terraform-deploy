terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.15.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

data "google_compute_network" "network" {
  name = basename(var.network)
}

data "google_compute_subnetwork" "subnetwork" {
  name   = basename(var.subnetwork)
  region = var.region
}

module "controller" {
  source = "./controller"

  project    = var.project
  region     = var.region
  zone       = var.zone
  subnetwork = var.subnetwork
  network    = var.network
  domain     = var.domain

  external_access = {}

  configs    = var.configs
  agent_cidr = [data.google_compute_subnetwork.subnetwork.ip_cidr_range]

  https_certs = var.https_certs == null ? null : {
    cert = file(var.https_certs.cert)
    key  = file(var.https_certs.key)
  }
}

module "image_ubuntu24" {
  source              = "./controller/image"
  for_each            = { for image in var.base_images : image.name => image }
  image_name          = each.value.name
  docker_name         = each.value.docker_name
  controller_instance = module.controller.controller
}

module "agent" {
  source   = "./agent"
  for_each = { for pool in var.gce_pools : pool.name => pool }

  controller_output = module.controller.agent_configs

  pool             = each.value.name
  instance_type    = each.value.machine_type
  agent_image      = each.value.image != null ? each.value.image : var.image_version[each.value.image_type]
  autoscale_config = each.value.autoscale_config

  accelerator_count = each.value.accelerator_count
  accelerator_type  = each.value.accelerator_type
}