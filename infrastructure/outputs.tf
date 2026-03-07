output "hub_resource_group" {
  value = azurerm_resource_group.hub.name
}

output "spoke_resource_group" {
  value = azurerm_resource_group.spoke.name
}

output "hub_vnet_id" {
  value = module.networking.hub_vnet_id
}

output "spoke_vnet_id" {
  value = module.networking.spoke_vnet_id
}

output "spoke_subnet_ids" {
  value = module.networking.spoke_subnet_ids
}

output "nat_gateway_public_ip" {
  value = module.networking.nat_gateway_public_ip
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}