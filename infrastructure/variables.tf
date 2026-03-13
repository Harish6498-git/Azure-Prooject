variable "project_name" {
  type    = string
  default = "secureapp"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "westus2"
}

variable "hub_vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "spoke_vnet_address_space" {
  type    = list(string)
  default = ["10.1.0.0/16"]
}

variable "hub_subnets" {
  type = map(object({
    address_prefixes                = list(string)
    default_outbound_access_enabled = bool
  }))
  default = {
    firewall   = { address_prefixes = ["10.0.1.0/24"], default_outbound_access_enabled = true }
    gateway    = { address_prefixes = ["10.0.2.0/24"], default_outbound_access_enabled = false }
    management = { address_prefixes = ["10.0.3.0/24"], default_outbound_access_enabled = false }
  }
}

variable "spoke_subnets" {
  type = map(object({
    address_prefixes                = list(string)
    default_outbound_access_enabled = bool
    service_endpoints               = list(string)
  }))
  default = {
    frontend   = { address_prefixes = ["10.1.1.0/24"], default_outbound_access_enabled = false, service_endpoints = [] }
    backend    = { address_prefixes = ["10.1.2.0/24"], default_outbound_access_enabled = false, service_endpoints = [] }
    database   = { address_prefixes = ["10.1.3.0/24"], default_outbound_access_enabled = false, service_endpoints = ["Microsoft.KeyVault"] }
    appgateway = { address_prefixes = ["10.1.4.0/24"], default_outbound_access_enabled = true, service_endpoints = [] }
  }
}

variable "vm_size" {
  type    = string
  default = "Standard_D2als_v7"
}

variable "ssh_public_key" {
  type = string
}

variable "db_user" {
  type    = string
  default = "sqladmin"
}

variable "db_pass" {
  type      = string
  sensitive = true
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "CloudOps"
  }
}