#Moving AI_search to it's own file since we're basically creating a resource module for it.

resource "azapi_resource" "ai_search" {
  for_each = { for k, v in var.ai_search_definition : k => v if v.existing_resource_id == null && var.create_byor == true }

  location  = var.location
  name      = try(each.value.name, null) != null ? each.value.name : (try(var.base_name, null) != null ? "${var.base_name}-${each.key}-ai-foundry-ai-search-${random_string.resource_token.result}" : "${each.key}-ai-foundry-ai-search-${random_string.resource_token.result}")
  parent_id = var.resource_group_resource_id
  type      = "Microsoft.Search/searchServices@2024-06-01-preview"
  body = {
    sku = {
      name = each.value.sku
    }

    identity = {
      type = "SystemAssigned"
    }

    properties = {

      # Search-specific properties
      replicaCount   = each.value.replica_count
      partitionCount = each.value.partition_count
      hostingMode    = each.value.hosting_mode
      semanticSearch = each.value.semantic_search_enabled == true ? "enabled" : "disabled"

      # Identity-related controls
      disableLocalAuth = each.value.local_authentication_enabled ? false : true #inverted logic to match the variable definition
      authOptions = {
        aadOrApiKey = {
          aadAuthFailureMode = "http401WithBearerChallenge"
        }
      }
      # Networking-related controls
      publicNetworkAccess = var.create_private_endpoints ? "Disabled" : "Enabled"
      networkRuleSet = {
        bypass = "None"
      }
    }
  }
  schema_validation_enabled = true
}

resource "azurerm_private_endpoint" "pe_aisearch" {
  for_each = { for k, v in var.ai_search_definition : k => v if v.existing_resource_id == null && var.create_byor == true && var.create_private_endpoints == true }

  location            = var.location
  name                = "${azapi_resource.ai_search[each.key].name}-private-endpoint"
  resource_group_name = local.resource_group_name
  subnet_id           = var.private_endpoint_subnet_resource_id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "${azapi_resource.ai_search[each.key].name}-private-link-service-connection"
    private_connection_resource_id = azapi_resource.ai_search[each.key].id
    subresource_names = [
      "searchService"
    ]
  }
  private_dns_zone_group {
    name                 = "${azapi_resource.ai_search[each.key].name}-dns-config"
    private_dns_zone_ids = [each.value.private_dns_zone_resource_id]
  }

  depends_on = [
    module.cosmosdb,
    azapi_resource.ai_search
  ]
}

resource "azurerm_role_assignment" "this_aisearch" {
  for_each = local.ai_search_rbac

  principal_id                           = each.value.role_assignment.principal_id
  scope                                  = azapi_resource.ai_search[each.value.ai_key].id
  condition                              = each.value.role_assignment.condition
  condition_version                      = each.value.role_assignment.condition_version
  delegated_managed_identity_resource_id = each.value.role_assignment.delegated_managed_identity_resource_id
  principal_type                         = each.value.role_assignment.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_assignment.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_assignment.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.role_assignment.skip_service_principal_aad_check
}

resource "azurerm_monitor_diagnostic_setting" "this_aisearch" {
  for_each = { for k, v in var.ai_search_definition : k => v if v.enable_diagnostic_settings == true }

  name                       = "diag-${azapi_resource.ai_search[each.key].name}"
  target_resource_id         = azapi_resource.ai_search[each.key].id
  log_analytics_workspace_id = workspace_resource_id = var.law_definition.existing_resource_id != null ? var.law_definition.existing_resource_id : module.log_analytics_workspace[0].resource_id

  enabled_log {
    category_group = "allLogs"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}
