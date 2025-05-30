module "configs" {
  source = "../../shared/configs"

  domain       = var.domain
  postgres_url = local.postgres_url
  gke_cluster  = var.gke_cluster
  use_proxy    = var.external_access.use_proxy
  agent_cidrs  = var.agent_cidr
  https_certs  = var.https_certs
  enable_saml  = lookup(var.configs, "enable_saml", false)
  configs = merge(
    var.configs,
    {
      gcs_provisioner = {
        bucket          = google_storage_bucket.pool_configs.name
        config_prefix   = "pools"
        update_interval = "60s"
      },
    },
  )
}
