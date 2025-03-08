resource "random_password" "db_password" {
  count   = var.sql_db == null ? 1 : 1
  length  = 16
  special = false
}

resource "google_sql_database_instance" "postgres_instance" {
  count            = var.sql_db == null ? 1 : 0
  name             = "${var.name}-pg-instance"
  database_version = "POSTGRES_17"
  region           = var.region

  settings {
    edition           = "ENTERPRISE"
    tier              = "db-f1-micro"
    availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled    = false # Disables public IP
      private_network = var.network
    }

    location_preference {
      zone = var.zone
    }
  }
}

resource "google_sql_database" "db" {
  count    = var.sql_db == null ? 1 : 0
  name     = "velda_db"
  instance = google_sql_database_instance.postgres_instance[0].name
}

resource "google_sql_user" "db_user" {
  count    = var.sql_db == null ? 1 : 0
  name     = "velda_user"
  instance = google_sql_database_instance.postgres_instance[0].name
  password = random_password.db_password[0].result
}

locals {
  postgres_url = var.sql_db == null ? "postgres://${google_sql_user.db_user[0].name}:${random_password.db_password[0].result}@${google_sql_database_instance.postgres_instance[0].private_ip_address}/${google_sql_database.db[0].name}" : var.sql_db
}
