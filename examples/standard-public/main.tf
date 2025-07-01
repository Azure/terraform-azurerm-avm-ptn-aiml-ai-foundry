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

locals {
  base_name = "public"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.2"

  availability_zones_filter = true
  geography_filter          = "Australia"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix        = [local.base_name]
  unique-length = 5
}

resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

module "ai_foundry" {
  source = "../../"

  base_name                    = local.base_name
  location                     = azurerm_resource_group.this.location
  ai_foundry_private_endpoints = {}
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
  ai_search_private_endpoints          = {}
  cosmos_db_private_endpoints          = {}
  create_ai_agent_service              = true # until fixed "Hub Workspace capabilityHost Not Found, please create the capability after Hub workspace Capability is created"
  create_ai_foundry_project            = true
  create_resource_group                = false
  existing_ai_search_resource_id       = null
  existing_cosmos_db_resource_id       = null
  existing_key_vault_resource_id       = null
  existing_storage_account_resource_id = null
  key_vault_private_endpoints          = {}
  resource_group_name                  = azurerm_resource_group.this.name
  storage_private_endpoints            = {}
}
