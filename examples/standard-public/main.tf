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

# This is the module call for AI Foundry Pattern - Standard Public Configuration
module "ai_foundry" {
  source = "../../"

  location                             = azurerm_resource_group.this.location
  name                                 = "ai-foundry-std-pub"
  resource_group_name                  = azurerm_resource_group.this.name
  ai_foundry_project_description       = "Standard AI Foundry project with agent services (public endpoints)"
  ai_foundry_project_name              = "AI-Foundry-Standard-Public"
  ai_foundry_project_private_endpoints = {}
  # Standard AI model deployment (single model)
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
  ai_search_private_endpoints   = {}
  ai_services_private_endpoints = {}
  cosmos_db_private_endpoints   = {}
  # Enable telemetry for the module
  enable_telemetry                             = var.enable_telemetry
  existing_log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.this.id
  key_vault_private_endpoints                  = {}
  storage_private_endpoints                    = {}
}
