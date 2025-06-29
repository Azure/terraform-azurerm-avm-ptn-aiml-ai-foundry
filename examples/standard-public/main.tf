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
  source                    = "Azure/avm-utl-regions/azurerm"
  version                   = "~> 0.1"
  availability_zones_filter = true
  geography_filter          = "Australia"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

resource "azurerm_application_insights" "this" {
  application_type    = "web"
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = module.naming.application_insights.name_unique
  resource_group_name = module.naming.resource_group.name_unique
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = module.naming.resource_group.name_unique
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

module "ai_foundry" {
  source = "../../"

  ai_foundry_project_description       = "Standard AI Foundry project with agent services (public endpoints)"
  ai_foundry_project_name              = "AI-Foundry-Standard-Public"
  create_ai_foundry_project            = true
  create_ai_agent_service              = true
  ai_foundry_project_private_endpoints = {}
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
  ai_search_private_endpoints  = {}
  ai_foundry_private_endpoints = {}
  cosmos_db_private_endpoints  = {}
  enable_telemetry             = true
  key_vault_private_endpoints  = {}
  location                     = module.regions.regions[random_integer.region_index.result].name
  name                         = "std-pub"
  storage_private_endpoints    = {}
}
