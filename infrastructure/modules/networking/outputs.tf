output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "spoke_vnet_id" {
  value = azurerm_virtual_network.spoke.id
}

output "hub_subnet_ids" {
  value = { for k, v in azurerm_subnet.hub : k => v.id }
}

output "spoke_subnet_ids" {
  value = { for k, v in azurerm_subnet.spoke : k => v.id }
}

output "nat_gateway_public_ip" {
  value = azurerm_public_ip.nat.ip_address
}