terraform {
  required_version = ">= 1.12, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.38"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

locals {
  base_name = "identity"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

  enable_telemetry       = var.enable_telemetry
  geography_filter       = "Australia"
  has_availability_zones = true
}

resource "random_shuffle" "locations" {
  input        = module.regions.valid_region_names
  result_count = 3
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"

  suffix        = [local.base_name]
  unique-length = 5
}

resource "azurerm_resource_group" "this" {
  location = random_shuffle.locations.result[0]
  name     = module.naming.resource_group.name_unique
}

module "user_assigned_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.3"

  location            = azurerm_resource_group.this.location
  name                = "uami-${module.naming.resource_group.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
}

module "ai_foundry" {
  source = "../../"

  base_name                  = local.base_name
  location                   = azurerm_resource_group.this.location
  resource_group_resource_id = azurerm_resource_group.this.id
  ai_foundry = {
    create_ai_agent_service = false
    name                    = module.naming.cognitive_account.name_unique
    managed_identities = {
      system_assigned            = true
      user_assigned_resource_ids = [module.user_assigned_identity.resource_id]
    }
  }
  ai_projects = {
    project_uami_only = {
      name                       = "uami-only-project"
      description                = "Project with only a user-assigned managed identity."
      display_name               = "UAMI only"
      create_project_connections = false
      managed_identities = {
        system_assigned            = false
        user_assigned_resource_ids = [module.user_assigned_identity.resource_id]
      }
    }
    project_both = {
      name                       = "project-both-identities"
      description                = "Project with system-assigned and user-assigned managed identities."
      display_name               = "System and UAMI"
      create_project_connections = false
      managed_identities = {
        system_assigned            = true
        user_assigned_resource_ids = [module.user_assigned_identity.resource_id]
      }
    }
  }
  create_byor              = false
  create_private_endpoints = false
  enable_telemetry         = var.enable_telemetry
}
