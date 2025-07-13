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

resource "random_shuffle" "locations" {
  input        = module.regions.valid_region_names
  result_count = 3
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix        = [local.base_name]
  unique-length = 5
}

resource "azurerm_resource_group" "this" {
  location = random_shuffle.locations.result[0]
  name     = module.naming.resource_group.name_unique
}

# Dependencies for AI Foundry
data "azurerm_client_config" "current" {}

# Storage Account for AI Foundry using AVM module
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.3"

  location                        = azurerm_resource_group.this.location
  name                            = module.naming.storage_account.name_unique
  resource_group_name             = azurerm_resource_group.this.name
  default_to_oauth_authentication = true
  managed_identities = {
    system_assigned = true
  }
  public_network_access_enabled = true
  shared_access_key_enabled     = false
  tags                          = {}
}

# Key Vault for AI Foundry using AVM module
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  location            = azurerm_resource_group.this.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  public_network_access_enabled = true
  tags                          = {}
}

# Cosmos DB for AI Foundry using AVM module
module "cosmos_db" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.8.0"

  location            = azurerm_resource_group.this.location
  name                = module.naming.cosmosdb_account.name_unique
  resource_group_name = azurerm_resource_group.this.name
  geo_locations = [
    {
      failover_priority = 0
      zone_redundant    = false
      location          = azurerm_resource_group.this.location
    }
  ]
  ip_range_filter = [
    "168.125.123.255",
    "170.0.0.0/24",
    "0.0.0.0",                                                                      #Accept connections from within public Azure datacenters. https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-the-azure-portal
    "104.42.195.92", "40.76.54.131", "52.176.6.30", "52.169.50.45", "52.187.184.26" #Allow access from the Azure portal. https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-global-azure-datacenters-or-other-sources-within-azure
  ]
  managed_identities = {
    system_assigned = true
  }
  network_acl_bypass_for_azure_services = true
  public_network_access_enabled = true
  tags                          = {}
}

# AI Search for AI Foundry using AVM module
module "ai_search" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.1.5"

  location            = azurerm_resource_group.this.location
  name                = module.naming.search_service.name_unique
  resource_group_name = azurerm_resource_group.this.name
  managed_identities = {
    system_assigned = true
  }
  public_network_access_enabled = true
  tags                          = {}
}

# This is the module call for AI Foundry Pattern - Standard Public Configuration
module "ai_foundry" {
  source = "../../"

  base_name = local.base_name
  location  = azurerm_resource_group.this.location
  ai_model_deployments = {
    "gpt-4o" = {
      name = "gpt-4o"
      model = {
        format  = "OpenAI"
        name    = "gpt-4o"
        version = "2024-11-20"
      }
      scale = {
        type     = "Standard"
        capacity = 1
      }
    }
  }
  ai_search_resource_id       = module.ai_search.resource_id
  cosmos_db_resource_id       = module.cosmos_db.resource_id
  storage_account_resource_id = module.storage_account.resource_id
  create_ai_agent_service     = false # default: false
  create_project_connections  = true  # default: false
  create_resource_group       = false # default: false
  resource_group_name         = azurerm_resource_group.this.name
}

# Role Assignments for AI Foundry Project System Identity
# These assignments allow the project to access the dependent resources
resource "azurerm_role_assignment" "cosmosdb_operator" {
  principal_id         = module.ai_foundry.ai_foundry_project_system_identity_principal_id
  scope                = module.cosmos_db.resource_id
  role_definition_name = "Cosmos DB Operator"

  depends_on = [
    module.ai_foundry,
    module.cosmos_db
  ]
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  principal_id         = module.ai_foundry.ai_foundry_project_system_identity_principal_id
  scope                = module.storage_account.resource_id
  role_definition_name = "Storage Blob Data Contributor"

  depends_on = [
    module.ai_foundry,
    module.storage_account
  ]
}

resource "azurerm_role_assignment" "search_index_data_contributor" {
  principal_id         = module.ai_foundry.ai_foundry_project_system_identity_principal_id
  scope                = module.ai_search.resource_id
  role_definition_name = "Search Index Data Contributor"

  depends_on = [
    module.ai_foundry,
    module.ai_search
  ]
}

resource "azurerm_role_assignment" "search_service_contributor" {
  principal_id         = module.ai_foundry.ai_foundry_project_system_identity_principal_id
  scope                = module.ai_search.resource_id
  role_definition_name = "Search Service Contributor"

  depends_on = [
    module.ai_foundry,
    module.ai_search
  ]
}
