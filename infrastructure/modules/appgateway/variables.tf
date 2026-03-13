variable "project_name" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "appgw_subnet_id" { type = string }
variable "frontend_private_ip" { type = string }
variable "tags" { type = map(string) }