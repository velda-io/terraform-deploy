terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.87.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "network" {
  id = var.vpc_id
}

data "aws_subnet" "subnetwork" {
  id = var.subnet_ids[0]
}

module "controller" {
  source = "./controller"

  region               = var.region
  zone                 = var.zone
  vpc_id               = var.vpc_id
  subnet_ids           = var.subnet_ids
  controller_subnet_id = var.controller_subnet_id
  domain               = var.domain

  external_access = {}

  configs = merge(
    var.configs,
    {
      aws_ssm_pool_provisioner = {
        region          = var.region
        config_prefix   = "/${var.name}/pools"
        update_interval = "60s"
      }
    }
  )

  controller_machine_type = var.controller_machine_type

  https_certs = var.https_certs == null ? null : {
    cert = file(var.https_certs.cert)
    key  = file(var.https_certs.key)
  }

  bin_authorized = var.bin_authorized

  connection_source = var.connection_source

  data_disk_size = var.data_disk_size
}

module "agent" {
  for_each = { for pool in var.pools : pool.name => pool }
  source   = "./agent"

  controller_output = module.controller.agent_configs

  pool             = each.value.name
  agent_ami        = each.value.ami != null ? each.value.ami : var.default_amis[each.value.ami_type]
  instance_type    = each.value.instance_type
  autoscale_config = each.value.autoscale_config
  init_script_content = each.value.init_script_content
}

/*
module "image_ubuntu24" {
  source              = "./controller/image"
  image_name          = "ubuntu24"
  docker_name         = "veldaio/base:24.04"
  controller_instance = module.controller.controller
}
*/
