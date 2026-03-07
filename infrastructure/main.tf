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

# ---- Resource Groups ----
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

# ---- Networking Module ----
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

# ---- Security Module ----
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

# ---- Key Vault Module ----
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