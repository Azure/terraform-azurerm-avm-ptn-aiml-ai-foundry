resource "random_string" "token" {
  length  = 5
  lower   = true
  numeric = true
  special = false
  upper   = false
}

locals {
  token = random_string.token.result

  # ---------------------------------------------------------------------------
  # Naming
  # ---------------------------------------------------------------------------
  name_suffix       = "${var.base_name}-${var.environment}-${local.token}"
  name_suffix_short = substr("${var.base_name}${var.environment}${local.token}", 0, 20)

  resource_group_name = coalesce(var.resource_group.name, "rg-aifoundry-${local.name_suffix}")

  names = {
    ai_foundry      = coalesce(var.resource_names.ai_foundry, "aif-${local.name_suffix}")
    key_vault       = coalesce(var.resource_names.key_vault, substr("kv-${local.name_suffix}", 0, 24))
    storage_account = coalesce(var.resource_names.storage_account, substr("st${replace(local.name_suffix, "-", "")}", 0, 24))
    cosmosdb        = coalesce(var.resource_names.cosmosdb, "cosmos-${local.name_suffix}")
    ai_search       = coalesce(var.resource_names.ai_search, "srch-${local.name_suffix}")

    # Video Indexer account names allow letters, digits and hyphens only (3-50 chars).
    video_indexer                 = coalesce(var.resource_names.video_indexer, substr("vi-${local.name_suffix}", 0, 50))
    video_indexer_storage_account = coalesce(var.resource_names.video_indexer_storage_account, substr("stvi${replace(local.name_suffix, "-", "")}", 0, 24))
  }

  video_indexer_location = var.deploy_video_indexer ? coalesce(var.video_indexer.location, var.location) : null

  # ---------------------------------------------------------------------------
  # Resource group that hosts the workload
  # ---------------------------------------------------------------------------
  resource_group_resource_id = var.resource_group.create ? azurerm_resource_group.this[0].id : data.azurerm_resource_group.this[0].id

  # ---------------------------------------------------------------------------
  # Networking supplied by the landing zone
  # ---------------------------------------------------------------------------
  agent_subnet_resource_id = var.agent_subnet.create ? azurerm_subnet.agent[0].id : var.agent_subnet.resource_id

  # ---------------------------------------------------------------------------
  # Private DNS zones supplied by the platform (connectivity subscription)
  # ---------------------------------------------------------------------------
  # The Video Indexer zone is only part of the set when that account is deployed, so
  # disabling it does not leave an unused zone behind or demand an extra zone ID.
  private_dns_zone_names = merge(
    {
      openai            = "privatelink.openai.azure.com"
      cognitiveservices = "privatelink.cognitiveservices.azure.com"
      ai_services       = "privatelink.services.ai.azure.com"
      blob              = "privatelink.blob.core.windows.net"
      vault             = "privatelink.vaultcore.azure.net"
      cosmos_sql        = "privatelink.documents.azure.com"
      search            = "privatelink.search.windows.net"
    },
    var.deploy_video_indexer ? {
      video_indexer = "privatelink.api.videoindexer.ai"
    } : {}
  )

  # One link per zone per supplied virtual network.
  private_dns_zone_links = var.create_private_dns_zones ? merge([
    for zone_key in keys(local.private_dns_zone_names) : {
      for link_key, vnet_id in var.private_dns_zone_virtual_network_resource_ids :
      "${zone_key}-${link_key}" => {
        zone_key                    = zone_key
        link_name                   = "link-${link_key}"
        virtual_network_resource_id = vnet_id
      }
    }
  ]...) : {}

  # Resolution order: an explicit per-zone override wins, then a zone this
  # configuration created, then one derived from the platform DNS resource group.
  private_dns_zone_ids = {
    for key, zone_name in local.private_dns_zone_names : key => (
      lookup(var.private_dns_zone_resource_ids, key, null) != null
      ? var.private_dns_zone_resource_ids[key]
      : (var.create_private_dns_zones
        ? azurerm_private_dns_zone.this[key].id
        : (var.private_dns_zone_resource_group_id != null
          ? "${var.private_dns_zone_resource_group_id}/providers/Microsoft.Network/privateDnsZones/${zone_name}"
      : null))
    )
  }

  # Only populated when this configuration owns the DNS zone groups.
  managed_private_dns_zone_ids = var.manage_private_dns_zone_groups ? local.private_dns_zone_ids : {
    for key in keys(local.private_dns_zone_names) : key => null
  }

  foundry_private_dns_zone_resource_ids = var.manage_private_dns_zone_groups ? [
    local.private_dns_zone_ids.openai,
    local.private_dns_zone_ids.cognitiveservices,
    local.private_dns_zone_ids.ai_services,
  ] : []

  # ---------------------------------------------------------------------------
  # Diagnostics
  # ---------------------------------------------------------------------------
  diagnostics_enabled = var.log_analytics_workspace_resource_id != null

  diagnostic_settings = local.diagnostics_enabled ? {
    to_law = {
      name                  = "diag-to-law"
      workspace_resource_id = var.log_analytics_workspace_resource_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}

  # Account scope on storage only accepts the Transaction metric category; asking for
  # AllMetrics there expands server-side and produces a perpetual plan diff.
  diagnostic_settings_storage_account = local.diagnostics_enabled ? {
    to_law = {
      name                  = "diag-to-law"
      workspace_resource_id = var.log_analytics_workspace_resource_id
      metric_categories     = ["Transaction"]
    }
  } : {}

  diagnostic_settings_blob = local.diagnostics_enabled ? {
    to_law = {
      name                  = "diag-to-law"
      workspace_resource_id = var.log_analytics_workspace_resource_id
      log_groups            = ["allLogs"]
      metric_categories     = ["Capacity", "Transaction"]
    }
  } : {}

  # ---------------------------------------------------------------------------
  # AI Foundry project wiring: every project is connected to the BYOR services.
  # ---------------------------------------------------------------------------
  ai_projects = {
    for key, project in var.ai_projects : key => {
      name                       = project.name
      display_name               = project.display_name
      description                = project.description
      sku                        = project.sku
      create_project_connections = true
      cosmos_db_connection = {
        existing_resource_id = module.cosmosdb.resource_id
      }
      ai_search_connection = {
        existing_resource_id = azapi_resource.ai_search.id
      }
      storage_account_connection = {
        existing_resource_id = module.storage_account.resource_id
      }
    }
  }
}
