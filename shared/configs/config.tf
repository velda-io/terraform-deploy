locals {
  config = merge({
    server = {
      grpc_address = ":50051"
      http_address = ":8081"
      host         = var.domain
      port         = 8080
      use_https    = var.https_certs != null
    }
    database = {
      sql = {
        driver = "pgx"
        url    = var.postgres_url
      }
    }
    user_auth = merge({
      access_token_private_key = "/run/velda/access-token-private-key.pem"
      access_token_public_key  = "/run/velda/access-token-public-key.pem"
      },
      var.include_legacy_configs ? {
        access_token_ttl_mins  = 60
        refresh_token_ttl_mins = 43200
      } : {},
      var.include_legacy_configs && var.configs.allow_public_register ? {
        allow_public_registration = true
      } : {},
      var.include_legacy_configs && var.configs.google_oauth_web != null ? {
        google_web = {
          client_id     = var.configs.google_oauth_web.client_id
          client_secret = var.configs.google_oauth_web.secret
        }
      } : {},
      var.include_legacy_configs && var.configs.google_oauth_cli != null ? {
        google_cli = {
          client_id     = var.configs.google_oauth_cli.client_id
          client_secret = var.configs.google_oauth_cli.secret
        }
      } : {},
      var.enable_saml ? {
        saml = {
          sp_cert_path = "/run/velda/saml.pub"
          sp_key_path  = "/run/velda/saml"
        }
    } : {})
    storage = {
      zfs = {
        pool = "zpool"
      }
    },
    provisioners = concat(
      var.configs.aws_ssm_pool_provisioner != null ? [
        {
          aws = var.configs.aws_ssm_pool_provisioner
        }
      ] : [],
      var.gke_cluster != null ? [
        {
          kubernetes = {
            namespace = var.gke_cluster.namespace
          }
        }
      ] : [],
      var.configs.gcs_provisioner != null ? [
        {
          gcs = var.configs.gcs_provisioner
        }
      ] : []
    )
    },
    var.use_proxy ? {
      jump_server = {
        listen_address   = ":2222"
        host_private_key = "/run/velda/jumphost"
        public_address   = "${var.domain}:2222"
        host_public_key  = "/run/velda/jumphost.pub"
      }
    } : {},
    var.include_legacy_configs && length(var.configs.default_instances) > 0 ? {
      default_instances = var.configs.default_instances
    } : {}
  )
}

