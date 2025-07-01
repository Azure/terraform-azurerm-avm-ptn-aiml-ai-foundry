module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.3"
  count   = var.deploy_storage_account ? 1 : 0

  location                        = var.location
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  default_to_oauth_authentication = true
  managed_identities = {
    system_assigned = true
  }
  network_rules = var.private_endpoint_subnet_id != null ? {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  } : null
  private_endpoints = var.private_endpoint_subnet_id != null ? {
    "blob" = {
      subnet_resource_id = var.private_endpoint_subnet_id
      subresource_name   = "blob"
      private_dns_zone_resource_ids = [
        var.private_dns_zone_resource_id_storage_blob
      ]
    }
  } : {}
  public_network_access_enabled = var.private_endpoint_subnet_id == null ? true : false
  shared_access_key_enabled     = false
  tags                          = var.tags
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"
  count   = var.deploy_key_vault ? 1 : 0

  location            = var.location
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  private_endpoints = var.private_endpoint_subnet_id != null ? {
    "vault" = {
      subnet_resource_id = var.private_endpoint_subnet_id
      subresource_name   = "vault"
      private_dns_zone_resource_ids = [
        var.private_dns_zone_resource_id_keyvault
      ]
    }
  } : {}
  public_network_access_enabled = var.private_endpoint_subnet_id == null ? true : false
  tags                          = var.tags
}

module "cosmos_db" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.8.0"
  count   = var.deploy_cosmos_db ? 1 : 0

  location            = var.location
  name                = var.cosmos_db_name
  resource_group_name = var.resource_group_name
  managed_identities = {
    system_assigned = true
  }
  private_endpoints = var.private_endpoint_subnet_id != null ? {
    "sql" = {
      subnet_resource_id = var.private_endpoint_subnet_id
      subresource_name   = "sql"
      private_dns_zone_resource_ids = [
        var.private_dns_zone_resource_id_cosmosdb
      ]
    }
  } : {}
  public_network_access_enabled = var.private_endpoint_subnet_id == null ? true : false
  tags                          = var.tags
}

module "ai_search" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.1.5"
  count   = var.deploy_ai_search ? 1 : 0

  location            = var.location
  name                = var.ai_search_name
  resource_group_name = var.resource_group_name
  managed_identities = {
    system_assigned = true
  }
  private_endpoints = var.private_endpoint_subnet_id != null ? {
    "searchService" = {
      subnet_resource_id = var.private_endpoint_subnet_id
      subresource_name   = "searchService"
      private_dns_zone_resource_ids = [
        var.private_dns_zone_resource_id_search
      ]
    }
  } : {}
  public_network_access_enabled = var.private_endpoint_subnet_id == null ? true : false
  tags                          = var.tags
}
