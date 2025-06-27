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

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "this" {
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = module.naming.resource_group.name_unique
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

# This is the module call for AI Foundry Pattern - Basic Configuration
# Basic only deploys AI Services - no Storage, Key Vault, Cosmos DB, AI Search, Container Registry, or Networking
module "ai_foundry" {
  source = "../../"

  location = module.regions.regions[random_integer.region_index.result].name
  name     = "ai-foundry-basic"
  # Basic AI model deployment (single model)
  ai_model_deployments = {
    "gpt-35-turbo" = {
      name = "gpt-35-turbo"
      model = {
        format  = "OpenAI"
        name    = "gpt-35-turbo"
        version = "0613"
      }
      scale = {
        type = "Standard"
      }
    }
  }
  # No agent service in basic (requires storage/other dependencies)
  create_ai_agent_service   = false
  create_ai_foundry_project = true
  # Enable telemetry for the module
  enable_telemetry               = true
  existing_ai_search_resource_id = "skip-deployment" # Skip AI search deployment
  existing_cosmos_db_resource_id = "skip-deployment" # Skip cosmos db deployment
  existing_key_vault_resource_id = "skip-deployment" # Skip key vault deployment
  resource_group_name            = module.naming.resource_group.name_unique
  # Basic deployment - no additional resources
  # Skip deployment by providing non-null values (these won't be used, just prevent deployment)
  existing_storage_account_resource_id = "skip-deployment" # Skip storage deployment
}
