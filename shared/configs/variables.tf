variable "name" {
  description = "Name of the deployment"
  type        = string
  default     = "velda"
}

variable "postgres_url" {
  description = "The PostgresSQL instance URL."
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "The domain name of the primary server"
  type        = string
}

variable "https_certs" {
  description = "Path of https certs"
  type = object({
    cert = string,
    key  = string,
  })
  default = null
}

variable "configs" {
  description = "Config options"
  type = object({
    allow_public_register = optional(bool, false)
    default_instances = optional(list(object({
      name  = string,
      image = string
    })), []),
    aws_ssm_pool_provisioner = optional(object({
      region = string,
      config_prefix   = string,
      update_interval = optional(string),
    }))
    gcs_provisioner = optional(object({
      bucket = string,
      config_prefix = string,
      update_interval = optional(string),
    }))
    google_oauth_web = optional(object({
      client_id = string,
      secret    = string,
    }))
    google_oauth_cli = optional(object({
      client_id = string,
      secret    = string,
    }))
  })
  default = {}
}

variable "allow_public_access" {
  description = "Allow public access to the server"
  type        = bool
  default     = false
}

// TODO: Make it general.
variable "gke_cluster" {
  description = "GKE cluster info"
  type = object({
    namespace = string
  })
  default = null
}

variable "agent_cidrs" {
  description = "CIDRs for agents"
  type        = list(string)
  default     = ["*"]
}