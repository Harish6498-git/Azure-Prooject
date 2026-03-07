# ---- Hub VNet ----
resource "azurerm_virtual_network" "hub" {
  name                = "${var.project_name}-hub-${var.environment}-vnet"
  location            = var.location
  resource_group_name = var.hub_resource_group
  address_space       = var.hub_vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "hub" {
  for_each                        = var.hub_subnets
  name                            = "${var.project_name}-hub-${each.key}-subnet"
  resource_group_name             = var.hub_resource_group
  virtual_network_name            = azurerm_virtual_network.hub.name
  address_prefixes                = each.value.address_prefixes
  default_outbound_access_enabled = each.value.default_outbound_access_enabled
}

# ---- Spoke VNet ----
resource "azurerm_virtual_network" "spoke" {
  name                = "${var.project_name}-spoke-${var.environment}-vnet"
  location            = var.location
  resource_group_name = var.spoke_resource_group
  address_space       = var.spoke_vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "spoke" {
  for_each                        = var.spoke_subnets
  name                            = "${var.project_name}-spoke-${each.key}-subnet"
  resource_group_name             = var.spoke_resource_group
  virtual_network_name            = azurerm_virtual_network.spoke.name
  address_prefixes                = each.value.address_prefixes
  default_outbound_access_enabled = each.value.default_outbound_access_enabled
  service_endpoints               = each.value.service_endpoints
}

# ---- VNet Peering ----
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "hub-to-spoke-${var.environment}"
  resource_group_name          = var.hub_resource_group
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "spoke-to-hub-${var.environment}"
  resource_group_name          = var.spoke_resource_group
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  use_remote_gateways          = false
}

# ---- NAT Gateway ----
resource "azurerm_public_ip" "nat" {
  name                = "${var.project_name}-nat-${var.environment}-pip"
  location            = var.location
  resource_group_name = var.spoke_resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "main" {
  name                    = "${var.project_name}-${var.environment}-natgw"
  location                = var.location
  resource_group_name     = var.spoke_resource_group
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "private_subnets" {
  for_each = {
    for k, v in var.spoke_subnets : k => v
    if !v.default_outbound_access_enabled
  }
  subnet_id      = azurerm_subnet.spoke[each.key].id
  nat_gateway_id = azurerm_nat_gateway.main.id
}
