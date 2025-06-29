module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.6.3"
  count   = var.deploy_storage_account ? 1 : 0

  location                        = var.location
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  public_network_access_enabled   = length(var.storage_private_endpoints) == 0 ? true : false
  default_to_oauth_authentication = true
  shared_access_key_enabled       = false

  managed_identities = {
    system_assigned = true
  }

  network_rules = length(var.storage_private_endpoints) > 0 ? {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  } : null

  private_endpoints = var.storage_private_endpoints
  tags              = var.tags
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.10.0"
  count   = var.deploy_key_vault ? 1 : 0

  location                      = var.location
  name                          = var.key_vault_name
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = length(var.key_vault_private_endpoints) == 0 ? true : false
  tenant_id                     = var.tenant_id
  private_endpoints             = var.key_vault_private_endpoints
  tags                          = var.tags
}

module "cosmos_db" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "~> 0.8.0"
  count   = var.deploy_cosmos_db ? 1 : 0

  location                      = var.location
  name                          = var.cosmos_db_name
  public_network_access_enabled = length(var.cosmos_db_private_endpoints) == 0 ? true : false

  managed_identities = {
    system_assigned = true
  }

  resource_group_name = var.resource_group_name
  private_endpoints   = var.cosmos_db_private_endpoints
  tags                = var.tags
}

module "ai_search" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "~> 0.1.5"
  count   = var.deploy_ai_search ? 1 : 0

  location                      = var.location
  name                          = var.ai_search_name
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = length(var.ai_search_private_endpoints) == 0 ? true : false

  managed_identities = {
    system_assigned = true
  }

  private_endpoints = var.ai_search_private_endpoints
  tags              = var.tags
}
