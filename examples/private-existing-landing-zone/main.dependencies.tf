###############################################################################
# BYOR dependent data services
#
# The AI Foundry pattern module is deployed in BYOR mode (create_byor = false),
# which is the supported production path. The dependent data services are owned
# here so that their lifecycle, naming, policy posture and private endpoints stay
# under landing zone control and survive a destroy of the Foundry stack.
###############################################################################

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"
  count   = var.deploy_key_vault ? 1 : 0

  location                        = var.location
  name                            = local.names.key_vault
  resource_group_name             = local.resource_group_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  diagnostic_settings             = local.diagnostic_settings
  enable_telemetry                = var.enable_telemetry
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
  private_endpoints = {
    vault = {
      name                          = "pe-${local.names.key_vault}-vault"
      private_dns_zone_resource_ids = local.managed_private_dns_zone_ids.vault != null ? [local.managed_private_dns_zone_ids.vault] : []
      subnet_resource_id            = var.private_endpoint_subnet_resource_id
      subresource_name              = "vault"
    }
  }
  private_endpoints_manage_dns_zone_group = var.manage_private_dns_zone_groups
  public_network_access_enabled           = false
  purge_protection_enabled                = true
  tags                                    = var.tags

  depends_on = [azurerm_resource_group.this]
}

# -----------------------------------------------------------------------------
# Storage account - AI Foundry agent file storage
# -----------------------------------------------------------------------------
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.9"

  location                            = var.location
  name                                = local.names.storage_account
  resource_group_name                 = local.resource_group_name
  access_tier                         = var.storage_account.access_tier
  account_kind                        = var.storage_account.account_kind
  account_replication_type            = var.storage_account.account_replication_type
  account_tier                        = var.storage_account.account_tier
  diagnostic_settings_blob            = local.diagnostic_settings_blob
  diagnostic_settings_storage_account = local.diagnostic_settings_storage_account
  enable_telemetry                    = var.enable_telemetry
  network_rules = {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
  private_endpoints = {
    blob = {
      name                          = "pe-${local.names.storage_account}-blob"
      private_dns_zone_resource_ids = local.managed_private_dns_zone_ids.blob != null ? [local.managed_private_dns_zone_ids.blob] : []
      subnet_resource_id            = var.private_endpoint_subnet_resource_id
      subresource_name              = "blob"
    }
  }
  private_endpoints_manage_dns_zone_group = var.manage_private_dns_zone_groups
  public_network_access_enabled           = false
  shared_access_key_enabled               = false
  tags                                    = var.tags

  depends_on = [azurerm_resource_group.this]
}

# -----------------------------------------------------------------------------
# Cosmos DB - AI Foundry agent thread storage
# -----------------------------------------------------------------------------
module "cosmosdb" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.10.0"

  location                   = var.location
  name                       = local.names.cosmosdb
  resource_group_name        = local.resource_group_name
  analytical_storage_enabled = false
  automatic_failover_enabled = var.cosmosdb.automatic_failover
  capacity = {
    total_throughput_limit = -1
  }
  consistency_policy = {
    consistency_level       = var.cosmosdb.consistency_level
    max_interval_in_seconds = var.cosmosdb.max_interval_in_seconds
    max_staleness_prefix    = var.cosmosdb.max_staleness_prefix
  }
  diagnostic_settings = local.diagnostic_settings
  enable_telemetry    = var.enable_telemetry
  # Always pass the primary region explicitly. Leaving this null falls back to the
  # upstream module default, which forces zone_redundant = true and ignores
  # var.cosmosdb.zone_redundant.
  geo_locations = concat(
    [{
      location          = var.location
      failover_priority = 0
      zone_redundant    = var.cosmosdb.zone_redundant
    }],
    [for region in var.cosmosdb.secondary_regions : {
      location          = region.location
      failover_priority = region.failover_priority
      zone_redundant    = region.zone_redundant
    }]
  )
  # Entra ID only. The Foundry project data-plane role assignments are created by
  # the pattern module.
  local_authentication_disabled         = true
  multiple_write_locations_enabled      = false
  network_acl_bypass_for_azure_services = true
  partition_merge_enabled               = false
  public_network_access_enabled         = false
  tags                                  = var.tags

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_private_endpoint" "cosmosdb" {
  count = var.manage_private_dns_zone_groups ? 1 : 0

  location            = var.location
  name                = "pe-${local.names.cosmosdb}-sql"
  resource_group_name = local.resource_group_name
  subnet_id           = var.private_endpoint_subnet_resource_id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "psc-${local.names.cosmosdb}"
    private_connection_resource_id = module.cosmosdb.resource_id
    subresource_names              = ["Sql"]
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [local.private_dns_zone_ids.cosmos_sql]
  }
  timeouts {
    delete = "90m"
  }
}

resource "azurerm_private_endpoint" "cosmosdb_unmanaged_dns" {
  count = var.manage_private_dns_zone_groups ? 0 : 1

  location            = var.location
  name                = "pe-${local.names.cosmosdb}-sql"
  resource_group_name = local.resource_group_name
  subnet_id           = var.private_endpoint_subnet_resource_id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "psc-${local.names.cosmosdb}"
    private_connection_resource_id = module.cosmosdb.resource_id
    subresource_names              = ["Sql"]
  }

  # DNS records are registered by the platform DINE/Modify policy against the hub zones.
  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
  timeouts {
    delete = "90m"
  }
}

# -----------------------------------------------------------------------------
# Azure AI Search - AI Foundry vector store
# -----------------------------------------------------------------------------
resource "azapi_resource" "ai_search" {
  location  = coalesce(var.ai_search.location, var.location)
  name      = local.names.ai_search
  parent_id = local.resource_group_resource_id
  type      = "Microsoft.Search/searchServices@2024-06-01-preview"
  body = {
    sku = {
      name = var.ai_search.sku
    }
    identity = {
      type = "SystemAssigned"
    }
    properties = merge(
      {
        replicaCount   = var.ai_search.replica_count
        partitionCount = var.ai_search.partition_count
        hostingMode    = "default"
        semanticSearch = var.ai_search.semantic_search

        disableLocalAuth = !var.ai_search.local_authentication_enabled

        publicNetworkAccess = "Disabled"
        networkRuleSet = {
          bypass = "None"
        }
      },
      # authOptions is rejected by the API when local auth is disabled.
      var.ai_search.local_authentication_enabled ? {
        authOptions = {
          aadOrApiKey = {
            aadAuthFailureMode = "http401WithBearerChallenge"
          }
        }
      } : {}
    )
  }
  schema_validation_enabled = true
  tags                      = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "ai_search" {
  count = local.diagnostics_enabled ? 1 : 0

  name                       = "diag-to-law"
  target_resource_id         = azapi_resource.ai_search.id
  log_analytics_workspace_id = var.log_analytics_workspace_resource_id

  enabled_log {
    category_group = "allLogs"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_private_endpoint" "ai_search" {
  count = var.manage_private_dns_zone_groups ? 1 : 0

  location            = var.location
  name                = "pe-${local.names.ai_search}"
  resource_group_name = local.resource_group_name
  subnet_id           = var.private_endpoint_subnet_resource_id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "psc-${local.names.ai_search}"
    private_connection_resource_id = azapi_resource.ai_search.id
    subresource_names              = ["searchService"]
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [local.private_dns_zone_ids.search]
  }
}

resource "azurerm_private_endpoint" "ai_search_unmanaged_dns" {
  count = var.manage_private_dns_zone_groups ? 0 : 1

  location            = var.location
  name                = "pe-${local.names.ai_search}"
  resource_group_name = local.resource_group_name
  subnet_id           = var.private_endpoint_subnet_resource_id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "psc-${local.names.ai_search}"
    private_connection_resource_id = azapi_resource.ai_search.id
    subresource_names              = ["searchService"]
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
}
