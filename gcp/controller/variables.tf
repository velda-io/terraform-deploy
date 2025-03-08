variable "name" {
  description = "Name of the deployment"
  type        = string
  default     = "velda"
}

variable "project" {
  description = "The name of the project"
  type        = string
}

variable "region" {
  description = "The region of the deployment"
  type        = string
}

variable "zone" {
  description = "The zone of the deployment. Must be within the region"
  type        = string
}

variable "network" {
  description = "Network for deployment"
  type        = string
}

variable "subnetwork" {
  description = "sub-network for the deployment"
  type        = string
}

variable "controller_machine_type" {
  description = "Machine type of controller instance"
  type        = string
  default     = "e2-small"
}

variable "data_disk_type" {
  description = "Type of the disk for storing user data"
  type        = string
  default     = "pd-balanced"
}

variable "data_disk_size" {
  description = "Size of disk for user data"
  type        = number
  default     = 100
}

variable "use_nat_gateway" {
  description = "Use NAT in the network"
  type        = bool
  default     = false
}

variable "sql_db" {
  description = "The PostgresSQL instance URL. If not set, a minimal CloudSQL instance will be provisioned"
  type        = string
  default     = null
  sensitive   = true
}

variable "domain" {
  description = "The domain name of the primary server"
  type        = string
}

variable "https_certs" {
  description = "Key of https certs"
  type = object({
    cert = string,
    key  = string,
  })
  default   = null
  sensitive = true
}

variable "google_oauth_web" {
  description = "OAuth client info for web based auth"
  type = object({
    client_id = string,
    secret    = string,
  })
  default   = null
  sensitive = true
}

variable "google_oauth_cli" {
  description = "OAuth client info for CLI based auth"
  type = object({
    client_id = string,
    secret    = string,
  })
  default   = null
  sensitive = true
}

variable "external_access" {
  description = "Optionsl for public IP access. Default to disallow"
  type = object({
    ip_address   = optional(string, null), // If not set, default to ephermeral public IP.
    network_tier = optional(string, "PREMIUM")
  })
  default = null
}

variable "configs" {
  description = "Config options"
  type        = any
  default     = {}
}

variable "gke_cluster" {
  description = "GKE agent pool backend"
  type = object({
    project    = string,
    location   = string,
    cluster_id = string,
    namespace  = string,
    # Whether to use internal IP to connect to the endpoint.
    internal_ip       = optional(bool, false),
  })
  default = null
}

variable "agent_cidr" {
  description = "CIDR for agent pool"
  type        = list(string)
}