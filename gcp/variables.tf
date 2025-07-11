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
  type        = any
  default     = {}
}

variable "gce_pools" {
  description = "Agent pools based on GCE"
  type = list(object({
    name              = string
    machine_type      = string
    image             = optional(string)
    image_type        = optional(string)
    autoscale_config  = any
    accelerator_type  = optional(string)
    accelerator_count = optional(number, 0)
  }))
  default = []
}

variable "base_instance_images" {
  description = "Base images for the deployment"
  type = list(object({
    name        = string
    docker_name = string
  }))
  default = []
}

variable "agent_image_version" {
  description = "The version of the image"
  type        = map(string)
}

variable "access_granted" {
  description = "Whether the access has been granted for the deployment"
  type        = bool
  default     = false
}

variable "controller_machine_type" {
  description = "Machine type of controller instance"
  type        = string
  default     = "n1-standard-4"
}

variable "external_access" {
  description = "Options for public IP access. Default to allow from internet."
  type = object({
    server_ip_address     = optional(string, null), // If not set, default to ephermeral public IP.
    network_tier          = optional(string, "PREMIUM")
    use_proxy             = optional(bool, true)                  // Whether the client should use a proxy to connect to the agent.
    allowed_source_ranges = optional(list(string), ["0.0.0.0/0"]) // Source ranges for the firewall rule
    allowed_source_tags   = optional(list(string), [])            // Source tags for the firewall rule
    use_nat_gateway       = optional(bool, false)                 // Whether to use NAT gateway for the internet network
    setup_firewall_rule   = optional(bool, true)                  // Whether to setup firewall rule for the external access
  })
  default = {

  }
}

variable "controller_image" {
  description = "value of the controller image to use"
  type        = string
}