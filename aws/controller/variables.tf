variable "name" {
  description = "Name of the deployment"
  type        = string
  default     = "velda"
}

variable "region" {
  description = "The region of the deployment"
  type        = string
}

variable "zone" {
  description = "The zone of the deployment. Must be within the region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the deployment"
  type        = string
}

variable "subnet_ids" {
  description = "sub-network for the deployment"
  type        = list(string)
}

variable "controller_machine_type" {
  description = "Machine type of controller instance"
  type        = string
  default     = "t2.micro"
}

variable "data_disk_type" {
  description = "Type of the disk for storing user data"
  type        = string
  default     = "gp3"
}

variable "data_disk_size" {
  description = "Size of disk for user data"
  type        = number
  default     = 20
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
    cluster_ipv4_cidr = string,
  })
  default = null
}

variable "bin_authorized" {
  description = "Authorized for binary access"
  type        = bool
  default     = false
}

variable "controller_subnet_id" {
  description = "Controller subnet"
  type        = string
}

variable "connection_source" {
  description = "Source of connection to the controller"
  type = list(object({
    cidr_ipv4                    = optional(string),
    cidr_ipv6                    = optional(string),
    prefix_list_id               = optional(string),
    referenced_security_group_id = optional(string),
  }))
}