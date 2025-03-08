locals {
  allow_public_access = var.external_access != null
}

module "configs" {
  source = "../../shared/configs"

  configs             = var.configs
  domain              = var.domain
  postgres_url        = local.postgres_url
  gke_cluster         = var.gke_cluster
  allow_public_access = local.allow_public_access
  agent_cidrs         = local.agent_cidrs
  https_certs         = var.https_certs
}

resource "aws_ssm_parameter" "configs" {
  for_each = module.configs.configs
  name     = "/${var.name}/${each.key}"
  type     = "String"
  value    = each.value
}

resource "aws_ssm_parameter" "agent_config" {
  name = "/${var.name}/agent/agent-config"
  type = "String"
  value = yamlencode({
    broker = {
      address = "${aws_instance.controller.private_ip}:50051"
    }
  })
}
