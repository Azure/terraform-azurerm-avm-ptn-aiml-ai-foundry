module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.3"
  count   = var.create_dependent_resources ? 1 : 0

  location                        = var.location
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  default_to_oauth_authentication = true
  managed_identities = {
    system_assigned = true
  }
  network_rules = var.create_private_endpoints ? {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  } : null
  private_endpoints = var.create_private_endpoints ? {
    "blob" = {
      subnet_resource_id = var.private_endpoint_subnet_id
      subresource_name   = "blob"
      private_dns_zone_resource_ids = [
        var.private_dns_zone_resource_id_storage_blob
      ]
    }
  } : {}
  public_network_access_enabled = var.create_private_endpoints ? false : true
  shared_access_key_enabled     = false
  tags                          = var.tags
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"
  count   = var.create_dependent_resources ? 1 : 0

  location            = var.location
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  private_endpoints = var.create_private_endpoints ? {
    "vault" = {
      subnet_resource_id = var.private_endpoint_subnet_id
      subresource_name   = "vault"
      private_dns_zone_resource_ids = [
        var.private_dns_zone_resource_id_keyvault
      ]
    }
  } : {}
  public_network_access_enabled = var.create_private_endpoints ? false : true
  tags                          = var.tags
}

module "cosmos_db" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.8.0"
  count   = var.create_dependent_resources ? 1 : 0

  location            = var.location
  name                = var.cosmos_db_name
  resource_group_name = var.resource_group_name
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
  private_endpoints = var.create_private_endpoints ? {
    "sql" = {
      subnet_resource_id = var.private_endpoint_subnet_id
      subresource_name   = "sql"
      private_dns_zone_resource_ids = [
        var.private_dns_zone_resource_id_cosmosdb
      ]
    }
  } : {}
  public_network_access_enabled = var.create_private_endpoints ? false : true
  tags                          = var.tags
}

module "ai_search" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.1.5"
  count   = var.create_dependent_resources ? 1 : 0

  location            = var.location
  name                = var.ai_search_name
  resource_group_name = var.resource_group_name
  managed_identities = {
    system_assigned = true
  }
  private_endpoints = var.create_private_endpoints ? {
    "searchService" = {
      subnet_resource_id = var.private_endpoint_subnet_id
      subresource_name   = "searchService"
      private_dns_zone_resource_ids = [
        var.private_dns_zone_resource_id_search
      ]
    }
  } : {}
  public_network_access_enabled = var.create_private_endpoints ? false : true
  tags                          = var.tags
}
