terraform {
  required_version = "~> 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# Example resource group for BYOR scenario
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Example Storage Account for BYOR scenario
resource "azurerm_storage_account" "this" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.this.location
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.this.name
}

# Example Key Vault for BYOR scenario
resource "azurerm_key_vault" "this" {
  location                   = azurerm_resource_group.this.location
  name                       = module.naming.key_vault.name_unique
  resource_group_name        = azurerm_resource_group.this.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}

# Example Cosmos DB for BYOR scenario
resource "azurerm_cosmosdb_account" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.cosmosdb_account.name_unique
  offer_type          = "Standard"
  resource_group_name = azurerm_resource_group.this.name

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    failover_priority = 0
    location          = azurerm_resource_group.this.location
  }
}

# Example AI Search for BYOR scenario
resource "azurerm_search_service" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.search_service.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "basic"
}

# Data source to get current client configuration
data "azurerm_client_config" "current" {}

# This is the module call for AI Foundry Pattern - BYOR Configuration
# This example uses existing resources instead of creating new ones
module "ai_foundry" {
  source = "../../"

  location = azurerm_resource_group.this.location
  name     = "ai-foundry-byor"

  # AI model deployment
  ai_model_deployments = {
    "gpt-4o-mini" = {
      name = "gpt-4o-mini"
      model = {
        format  = "OpenAI"
        name    = "gpt-4o-mini"
        version = "2024-07-18"
      }
      scale = {
        type = "Standard"
      }
    }
  }

  # Enable AI Foundry Project and Agent Service
  create_ai_foundry_project = true
  create_ai_agent_service   = true

  # Use existing resources (BYOR)
  resource_group_name                  = azurerm_resource_group.this.name
  existing_storage_account_resource_id = azurerm_storage_account.this.id
  existing_key_vault_resource_id       = azurerm_key_vault.this.id
  existing_cosmos_db_resource_id       = azurerm_cosmosdb_account.this.id
  existing_ai_search_resource_id       = azurerm_search_service.this.id

  # Enable telemetry for the module
  enable_telemetry = true
}
