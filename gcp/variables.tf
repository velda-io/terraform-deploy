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

variable "base_images" {
  description = "Base images for the deployment"
  type = list(object({
    name        = string
    docker_name = string
  }))
  default = []
}

variable "image_version" {
  description = "The version of the image"
  type        = map(string)
}
