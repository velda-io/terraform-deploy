module "configs" {
  source = "../../shared/configs"

  domain              = var.domain
  postgres_url        = local.postgres_url
  gke_cluster         = var.gke_cluster
  allow_public_access = var.external_access != null
  agent_cidrs         = var.agent_cidr
  https_certs         = var.https_certs
  configs             = merge(
    var.configs,
    {
      gcs_provisioner = {
        bucket = google_storage_bucket.pool_configs.name
        config_prefix = "pools"
        update_interval = "60s"
      },
    },
  )
}
