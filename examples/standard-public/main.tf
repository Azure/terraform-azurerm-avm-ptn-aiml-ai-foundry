terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  storage_use_azuread = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"

  availability_zones_filter = true
  geography_filter          = "Australia"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

resource "random_string" "example_suffix" {
  length  = 5
  lower   = true
  numeric = true
  special = false
  upper   = false
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

resource "azurerm_resource_group" "example" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = "rg-standard-public-${random_string.example_suffix.result}"
}

resource "azurerm_application_insights" "this" {
  application_type    = "web"
  location            = azurerm_resource_group.example.location
  name                = module.naming.application_insights.name_unique
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.example.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.example.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

module "ai_foundry" {
  source = "../../"

  location                                     = azurerm_resource_group.example.location
  name                                         = "std-pub"
  create_resource_group                        = false
  resource_group_name                          = azurerm_resource_group.example.name
  existing_application_insights_resource_id    = azurerm_application_insights.this.id
  existing_log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.this.id
  ai_foundry_private_endpoints                 = {}
  ai_foundry_project_description               = "Standard AI Foundry project with agent services (public endpoints)"
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
  cosmos_db_private_endpoints          = {}
  ai_search_private_endpoints          = {}
  key_vault_private_endpoints          = {}
  storage_private_endpoints            = {}
  create_ai_agent_service              = true
  create_ai_foundry_project            = true
  existing_ai_search_resource_id       = null
  existing_cosmos_db_resource_id       = null
  existing_key_vault_resource_id       = null
  existing_storage_account_resource_id = null
}
