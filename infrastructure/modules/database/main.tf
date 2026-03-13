resource "azurerm_mssql_server" "main" {
  name                         = "${var.project_name}-${var.environment}-sqlserver"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  version                      = "12.0"
  administrator_login          = var.db_user
  administrator_login_password = var.db_pass
  public_network_access_enabled = false
  tags = var.tags
}

resource "azurerm_mssql_database" "main" {
  name      = "${var.project_name}-tododb"
  server_id = azurerm_mssql_server.main.id
  sku_name  = "Basic"
  max_size_gb = 2
  tags = var.tags
}

resource "azurerm_private_endpoint" "sql" {
  name                = "${var.project_name}-sql-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.db_subnet_id

  private_service_connection {
    name                           = "sql-private-connection"
    private_connection_resource_id = azurerm_mssql_server.main.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
  tags = var.tags
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "sql-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = var.spoke_vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "sql" {
  name                = azurerm_mssql_server.main.name
  zone_name           = azurerm_private_dns_zone.sql.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.sql.private_service_connection[0].private_ip_address]
}