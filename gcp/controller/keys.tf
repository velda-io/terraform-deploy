resource "tls_private_key" "auth_token_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256" # This corresponds to prime256v1 (secp256r1)
}

resource "tls_private_key" "jumphost_key" {
  count     = var.external_access.use_proxy ? 1 : 0
  algorithm = "ED25519"
}

resource "tls_private_key" "saml_sp_key" {
  count      = var.enable_saml ? 1 : 0
  algorithm  = "ECDSA"
  ecdsa_curve = "P256"
}

resource "google_secret_manager_secret" "jumphosts_public_key" {
  count     = var.external_access.use_proxy ? 1 : 0
  secret_id = "${var.name}-jumphost-public"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "jumphost_public_value" {
  count       = var.external_access.use_proxy ? 1 : 0
  secret      = google_secret_manager_secret.jumphosts_public_key[0].id
  secret_data = tls_private_key.jumphost_key[0].public_key_openssh
}

resource "google_secret_manager_secret_iam_member" "jumphost_public_access" {
  count     = var.external_access.use_proxy ? 1 : 0
  secret_id = google_secret_manager_secret.jumphosts_public_key[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_service_account.controller_sa.email}"
}

resource "google_secret_manager_secret" "jumphosts_private_key" {
  count     = var.external_access.use_proxy ? 1 : 0
  secret_id = "${var.name}-jumphost-private"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "jumphost_private_value" {
  count       = var.external_access.use_proxy ? 1 : 0
  secret      = google_secret_manager_secret.jumphosts_private_key[0].id
  secret_data = tls_private_key.jumphost_key[0].private_key_pem
}

resource "google_secret_manager_secret_iam_member" "jumphost_private_access" {
  count     = var.external_access.use_proxy ? 1 : 0
  secret_id = google_secret_manager_secret.jumphosts_private_key[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_service_account.controller_sa.email}"
}

resource "google_secret_manager_secret" "auth_public_key" {
  secret_id = "${var.name}-auth-public-key"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "auth_public_key" {
  secret      = google_secret_manager_secret.auth_public_key.id
  secret_data = tls_private_key.auth_token_key.public_key_pem
}

resource "google_project_iam_member" "agent_sa_secret_access" {
  project = var.project
  member  = "serviceAccount:${data.google_service_account.agent_sa.email}"
  role    = "roles/secretmanager.secretAccessor"
}

resource "google_secret_manager_secret" "saml_sp_public_key" {
  count     = var.enable_saml ? 1 : 0
  secret_id = "${var.name}-saml-sp-public-key"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "saml_sp_public_key" {
  count       = var.enable_saml ? 1 : 0
  secret      = google_secret_manager_secret.saml_sp_public_key[0].id
  secret_data = tls_private_key.saml_sp_key[0].public_key_openssh
}

resource "google_secret_manager_secret" "saml_sp_private_key" {
  count     = var.enable_saml ? 1 : 0
  secret_id = "${var.name}-saml-sp-private-key"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "saml_sp_private_key" {
  count       = var.enable_saml ? 1 : 0
  secret      = google_secret_manager_secret.saml_sp_private_key[0].id
  secret_data = tls_private_key.saml_sp_key[0].private_key_pem
}
