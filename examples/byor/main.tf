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
  version = "0.5.2"
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
  version = "0.4.2"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Log Analytics Workspace for Container App Environment and AVM modules
resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

# ========================================
# Create Prerequisite Resources (BYO Resources)
# ========================================

# Storage Account to be used as existing resource
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.3"

  location            = azurerm_resource_group.this.location
  name                = module.naming.storage_account.name_unique
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
}

# Key Vault to be used as existing resource
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  location            = azurerm_resource_group.this.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
}

# Cosmos DB Account to be used as existing resource
module "cosmos_db" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.8.0"

  location            = azurerm_resource_group.this.location
  name                = module.naming.cosmosdb_account.name_unique
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
}

# AI Search Service to be used as existing resource
module "ai_search" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.1.5"

  location            = azurerm_resource_group.this.location
  name                = module.naming.search_service.name_unique
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# ========================================
# AI Foundry Pattern with BYO Resources
# ========================================

# This is the module call for AI Foundry Pattern - BYO Resources Configuration
module "ai_foundry" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  name                = "ai-foundry-byor"
  resource_group_name = azurerm_resource_group.this.name

  # Use existing resources created above
  existing_storage_account_resource_id = module.storage_account.resource_id
  existing_key_vault_resource_id       = module.key_vault.resource_id
  existing_cosmos_db_resource_id       = module.cosmos_db.resource_id
  existing_ai_search_resource_id       = module.ai_search.resource_id

  ai_foundry_project_description = "AI Foundry project demonstrating Bring Your Own Resources (BYOR)"
  ai_foundry_project_name        = "AI-Foundry-BYOR"

  # Standard AI model deployment
  ai_model_deployments = {
    "gpt-4o" = {
      name = "gpt-4o"
      model = {
        format  = "OpenAI"
        name    = "gpt-4o"
        version = "2024-08-06"
      }
      scale = {
        type = "Standard"
      }
    }
  }

  # Enable agent service (no agent subnet required for BYOR public scenario)
  create_ai_agent_service = true

  enable_telemetry                             = true
  existing_log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.this.id
}
