variable "project_name" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "hub_resource_group" { type = string }
variable "spoke_resource_group" { type = string }
variable "hub_vnet_address_space" { type = list(string) }
variable "spoke_vnet_address_space" { type = list(string) }
variable "tags" { type = map(string) }

variable "hub_subnets" {
  type = map(object({
    address_prefixes                = list(string)
    default_outbound_access_enabled = bool
  }))
}

variable "spoke_subnets" {
  type = map(object({
    address_prefixes                = list(string)
    default_outbound_access_enabled = bool
    service_endpoints               = list(string)
  }))
}