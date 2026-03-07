output "frontend_nsg_id" {
  value = azurerm_network_security_group.frontend.id
}

output "backend_nsg_id" {
  value = azurerm_network_security_group.backend.id
}

output "database_nsg_id" {
  value = azurerm_network_security_group.database.id
}