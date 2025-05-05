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
  description = "The VPC id of the deployment"
  type        = string
}

variable "subnet_ids" {
  description = "sub-network for the deployment"
  type        = list(string)
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
  description = "Config options. Definition see ../shared/configs/variables.tf"
  type        = any
  default     = {}
}

variable "pools" {
  description = "Agent pools based on AWS"
  type = list(object({
    name             = string
    instance_type    = string
    ami              = optional(string)
    ami_type         = optional(string)
    autoscale_config = any
  }))
  default = []
}


variable "default_amis" {
  description = "Default AMIs by machine types"
  type        = map(string)
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
