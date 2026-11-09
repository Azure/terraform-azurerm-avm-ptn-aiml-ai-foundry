###############################################################################
# Azure AI Video Indexer (optional)
#
# Only created when deploy_video_indexer = true. Nothing else in this
# configuration depends on it, so it can be added to an existing deployment or
# removed again without touching the Foundry stack.
#
# Video Indexer analyses EXISTING footage - scenes, shots, keyframes,
# transcription, OCR, faces, objects, speakers - and returns a time-coded
# index. It does not generate video. An agent or model reasons over that index,
# which is why this pairs naturally with Foundry rather than replacing it.
#
# Three resources are needed because of how the service authenticates:
#   1. a DEDICATED storage account, which Video Indexer uses for its own
#      artefacts and must not share with the Foundry agent storage,
#   2. a user-assigned managed identity, and
#   3. the account itself.
#
# The user-assigned identity exists to break a chicken-and-egg problem. The
# account needs storage access at CREATE time, but a system-assigned identity
# does not exist until after the account is created, so a role assignment on it
# can never be in place early enough. A user-assigned identity can be created
# and granted access first, then handed to the account. The system-assigned
# identity is enabled as well and granted access afterwards, because some
# Video Indexer data-plane paths expect it.
###############################################################################

# -----------------------------------------------------------------------------
# Identity used by Video Indexer to reach its storage account
# -----------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "video_indexer" {
  count = var.deploy_video_indexer ? 1 : 0

  location            = local.video_indexer_location
  name                = "id-${local.names.video_indexer}"
  resource_group_name = local.resource_group_name
  tags                = var.tags

  depends_on = [azurerm_resource_group.this]
}

# -----------------------------------------------------------------------------
# Dedicated storage account
#
# Video Indexer requires its own storage account in the same region as the
# account. Public access stays disabled; Video Indexer reaches it as a trusted
# Azure service via the AzureServices bypass, using the identities below.
# -----------------------------------------------------------------------------
module "video_indexer_storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.9"
  count   = var.deploy_video_indexer ? 1 : 0

  location                            = local.video_indexer_location
  name                                = local.names.video_indexer_storage_account
  resource_group_name                 = local.resource_group_name
  access_tier                         = "Hot"
  account_kind                        = "StorageV2"
  account_replication_type            = var.video_indexer.storage_account_replication_type
  account_tier                        = "Standard"
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
      name                          = "pe-${local.names.video_indexer_storage_account}-blob"
      private_dns_zone_resource_ids = local.managed_private_dns_zone_ids.blob != null ? [local.managed_private_dns_zone_ids.blob] : []
      subnet_resource_id            = var.private_endpoint_subnet_resource_id
      subresource_name              = "blob"
    }
  }
  private_endpoints_manage_dns_zone_group = var.manage_private_dns_zone_groups
  public_network_access_enabled           = false
  shared_access_key_enabled               = var.video_indexer.storage_account_shared_key_enabled
  tags                                    = var.tags

  depends_on = [azurerm_resource_group.this]
}

# Granted BEFORE the account is created, so storage is reachable at create time.
resource "azurerm_role_assignment" "video_indexer_storage_uai" {
  count = var.deploy_video_indexer ? 1 : 0

  principal_id         = azurerm_user_assigned_identity.video_indexer[0].principal_id
  scope                = module.video_indexer_storage[0].resource_id
  principal_type       = "ServicePrincipal"
  role_definition_name = "Storage Blob Data Contributor"
}

# -----------------------------------------------------------------------------
# Video Indexer account
# -----------------------------------------------------------------------------
resource "azapi_resource" "video_indexer" {
  count = var.deploy_video_indexer ? 1 : 0

  location  = local.video_indexer_location
  name      = local.names.video_indexer
  parent_id = local.resource_group_resource_id
  type      = "Microsoft.VideoIndexer/accounts@2025-04-01"
  body = {
    properties = merge(
      {
        publicNetworkAccess = var.video_indexer.public_network_access_enabled ? "Enabled" : "Disabled"
        storageServices = {
          resourceId           = module.video_indexer_storage[0].resource_id
          userAssignedIdentity = azurerm_user_assigned_identity.video_indexer[0].id
        }
      },
      var.video_indexer.connect_to_ai_foundry ? {
        openAiServices = {
          resourceId           = module.ai_foundry.ai_foundry_id
          userAssignedIdentity = azurerm_user_assigned_identity.video_indexer[0].id
        }
      } : {}
    )
  }
  response_export_values    = ["properties.accountId"]
  schema_validation_enabled = true
  tags                      = var.tags

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.video_indexer[0].id]
  }

  depends_on = [
    azurerm_role_assignment.video_indexer_storage_uai,
    azurerm_role_assignment.video_indexer_openai_uai,
  ]
}

# Granted after creation - the principal does not exist before then.
resource "azurerm_role_assignment" "video_indexer_storage_smi" {
  count = var.deploy_video_indexer ? 1 : 0

  principal_id         = azapi_resource.video_indexer[0].identity[0].principal_id
  scope                = module.video_indexer_storage[0].resource_id
  principal_type       = "ServicePrincipal"
  role_definition_name = "Storage Blob Data Contributor"
}

# Lets Video Indexer call the Foundry account for textual summarization.
resource "azurerm_role_assignment" "video_indexer_openai_uai" {
  count = var.deploy_video_indexer && var.video_indexer.connect_to_ai_foundry ? 1 : 0

  principal_id         = azurerm_user_assigned_identity.video_indexer[0].principal_id
  scope                = module.ai_foundry.ai_foundry_id
  principal_type       = "ServicePrincipal"
  role_definition_name = "Cognitive Services OpenAI User"
}

resource "azurerm_monitor_diagnostic_setting" "video_indexer" {
  count = var.deploy_video_indexer && local.diagnostics_enabled ? 1 : 0

  name                       = "diag-to-law"
  target_resource_id         = azapi_resource.video_indexer[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_resource_id

  enabled_log {
    category_group = "allLogs"
  }
}

# -----------------------------------------------------------------------------
# Private endpoint
#
# Subresource "account", zone privatelink.api.videoindexer.ai. The endpoint is
# placed in the workload VNet even when the account is in another region.
# -----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "video_indexer" {
  count = var.deploy_video_indexer && var.manage_private_dns_zone_groups ? 1 : 0

  location            = var.location
  name                = "pe-${local.names.video_indexer}"
  resource_group_name = local.resource_group_name
  subnet_id           = var.private_endpoint_subnet_resource_id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "psc-${local.names.video_indexer}"
    private_connection_resource_id = azapi_resource.video_indexer[0].id
    subresource_names              = ["account"]
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [local.private_dns_zone_ids.video_indexer]
  }

  lifecycle {
    precondition {
      condition     = local.private_dns_zone_ids.video_indexer != null
      error_message = "deploy_video_indexer = true needs a private DNS zone for privatelink.api.videoindexer.ai. Supply private_dns_zone_resource_ids[\"video_indexer\"], set private_dns_zone_resource_group_id so it can be derived, or set create_private_dns_zones = true in a sandbox."
    }
  }
}

resource "azurerm_private_endpoint" "video_indexer_unmanaged_dns" {
  count = var.deploy_video_indexer && !var.manage_private_dns_zone_groups ? 1 : 0

  location            = var.location
  name                = "pe-${local.names.video_indexer}"
  resource_group_name = local.resource_group_name
  subnet_id           = var.private_endpoint_subnet_resource_id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "psc-${local.names.video_indexer}"
    private_connection_resource_id = azapi_resource.video_indexer[0].id
    subresource_names              = ["account"]
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
}
