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
    init_script_content = optional(string)
  }))
  default = []
}

variable "data_disk_size" {
  description = "Size of disk for user data"
  type        = number
  default     = 20
}
variable "controller_amis" {
  description = "Controller AMIs by region"
  type        = map(string)
  default     = {
    "us-east-1" = "ami-0dcf02acfb11df3d3"
  }
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

variable "connection_source" {
  description = "Source of connection to the controller"
  type = list(object({
    cidr_ipv4                    = optional(string),
    cidr_ipv6                    = optional(string),
    prefix_list_id               = optional(string),
    referenced_security_group_id = optional(string),
  }))
  default = [{
    cidr_ipv4 = "0.0.0.0/0"
  }]
}

variable "controller_machine_type" {
  description = "Machine type of controller instance"
  type        = string
  default     = "t2.micro"
}
