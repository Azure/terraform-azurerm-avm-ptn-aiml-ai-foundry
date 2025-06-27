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

# Application Insights for AI Foundry (required)
resource "azurerm_application_insights" "this" {
  application_type    = "web"
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = module.naming.application_insights.name_unique
  resource_group_name = module.naming.resource_group.name_unique
}

# Log Analytics Workspace for Container App Environment
resource "azurerm_log_analytics_workspace" "this" {
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = module.naming.resource_group.name_unique
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

# This is the module call for AI Foundry Pattern - Standard Public Configuration
module "ai_foundry" {
  source = "../../"

  location                             = module.regions.regions[random_integer.region_index.result].name
  name                                 = "ai-foundry-std-pub"
  ai_foundry_project_description       = "Standard AI Foundry project with agent services (public endpoints)"
  ai_foundry_project_name              = "AI-Foundry-Standard-Public"
  ai_foundry_project_private_endpoints = {}
  # Standard AI model deployment (single model) - Available in Australia
  ai_model_deployments = {
    "gpt-4o" = {
      name = "gpt-4.1"
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1"
        version = "2025-04-14"
      }
      scale = {
        type     = "GlobalStandard"
        capacity = 1
      }
    }
  }
  ai_search_private_endpoints   = {}
  ai_services_private_endpoints = {}
  cosmos_db_private_endpoints   = {}
  # Enable telemetry for the module
  enable_telemetry            = true
  resource_group_name         = module.naming.resource_group.name_unique
  key_vault_private_endpoints = {}
  storage_private_endpoints   = {}
}
