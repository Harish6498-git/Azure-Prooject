terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_client_config" "current" {}

# ============================================================================
# Phase 1: Foundation
# ============================================================================

resource "azurerm_resource_group" "hub" {
  name     = "${var.project_name}-hub-${var.environment}-rg"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "spoke" {
  name     = "${var.project_name}-spoke-${var.environment}-rg"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "security" {
  name     = "${var.project_name}-security-${var.environment}-rg"
  location = var.location
  tags     = local.common_tags
}

module "networking" {
  source               = "./modules/networking"
  project_name         = var.project_name
  environment          = var.environment
  location             = var.location
  hub_resource_group   = azurerm_resource_group.hub.name
  spoke_resource_group = azurerm_resource_group.spoke.name
  hub_vnet_address_space   = var.hub_vnet_address_space
  spoke_vnet_address_space = var.spoke_vnet_address_space
  hub_subnets   = var.hub_subnets
  spoke_subnets = var.spoke_subnets
  tags = local.common_tags
}

module "security" {
  source              = "./modules/security"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  frontend_subnet_id  = module.networking.spoke_subnet_ids["frontend"]
  backend_subnet_id   = module.networking.spoke_subnet_ids["backend"]
  db_subnet_id        = module.networking.spoke_subnet_ids["database"]
  tags = local.common_tags
}

module "keyvault" {
  source              = "./modules/keyvault"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.security.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  spoke_vnet_id       = module.networking.spoke_vnet_id
  db_subnet_id        = module.networking.spoke_subnet_ids["database"]
  tags = local.common_tags
}

# ============================================================================
# Phase 2: Compute + Database + Application Gateway
# ============================================================================

module "database" {
  source              = "./modules/database"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  db_subnet_id        = module.networking.spoke_subnet_ids["database"]
  spoke_vnet_id       = module.networking.spoke_vnet_id
  db_user             = var.db_user
  db_pass             = var.db_pass
  tags = local.common_tags
}

module "compute" {
  source              = "./modules/compute"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  frontend_subnet_id  = module.networking.spoke_subnet_ids["frontend"]
  backend_subnet_id   = module.networking.spoke_subnet_ids["backend"]
  vm_size             = var.vm_size
  ssh_public_key      = var.ssh_public_key
  tags = local.common_tags
}

module "appgateway" {
  source               = "./modules/appgateway"
  project_name         = var.project_name
  environment          = var.environment
  location             = var.location
  resource_group_name  = azurerm_resource_group.spoke.name
  appgw_subnet_id      = module.networking.spoke_subnet_ids["appgateway"]
  frontend_private_ip  = module.compute.frontend_private_ip
  tags = local.common_tags
}