output "hub_resource_group" {
  value = azurerm_resource_group.hub.name
}
output "spoke_resource_group" {
  value = azurerm_resource_group.spoke.name
}
output "nat_gateway_public_ip" {
  value = module.networking.nat_gateway_public_ip
}
output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}
output "backend_private_ip" {
  value = module.compute.backend_private_ip
}
output "frontend_private_ip" {
  value = module.compute.frontend_private_ip
}
output "sql_server_fqdn" {
  value = module.database.sql_server_fqdn
}
output "app_gateway_public_ip" {
  description = "Access the app at this IP"
  value       = module.appgateway.appgw_public_ip
}