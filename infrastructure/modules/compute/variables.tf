variable "project_name" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "frontend_subnet_id" { type = string }
variable "backend_subnet_id" { type = string }
variable "vm_size" {
  type    = string
  default = "Standard_D2als_v7"
}
variable "ssh_public_key" { type = string }
variable "tags" { type = map(string) }