resource "azapi_resource" "ai_foundry" {
  location  = var.location
  name      = local.ai_foundry_name
  parent_id = var.resource_group_resource_id
  type      = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  body = {

    kind = "AIServices",
    sku = {
      name = var.ai_foundry.sku
    }

    properties = {
      disableLocalAuth       = var.ai_foundry.disable_local_auth
      allowProjectManagement = var.ai_foundry.allow_project_management
      customSubDomainName    = local.ai_foundry_name
      publicNetworkAccess    = var.create_private_endpoints ? "Disabled" : "Enabled"
      networkAcls = {
        defaultAction       = "Allow"
        virtualNetworkRules = []
        ipRules             = []
      }

      # Enable VNet injection for Standard Agents
      networkInjections = var.ai_foundry.create_ai_agent_service ? var.ai_foundry.network_injections : null
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  tags                      = var.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "identity" {
    for_each = (var.ai_foundry.managed_identities.system_assigned || length(var.ai_foundry.managed_identities.user_assigned_resource_ids) > 0) ? ["identity"] : []

    content {
      type         = var.ai_foundry.managed_identities.system_assigned && length(var.ai_foundry.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.ai_foundry.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
      identity_ids = var.ai_foundry.managed_identities.user_assigned_resource_ids
    }
  }
}


resource "azapi_resource" "ai_agent_capability_host" {
  count = var.ai_foundry.create_ai_agent_service && var.ai_foundry.network_injections == null ? 1 : 0

  name      = "ai-agent-service-${random_string.resource_token.result}"
  parent_id = azapi_resource.ai_foundry.id
  type      = "Microsoft.CognitiveServices/accounts/capabilityHosts@2025-04-01-preview"
  body = {
    properties = {
      capabilityHostKind = "Agents"
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [azapi_resource.ai_foundry]
}

resource "azapi_resource" "ai_model_deployment" {
  for_each = var.ai_model_deployments

  name      = each.value.name
  parent_id = azapi_resource.ai_foundry.id
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-04-01-preview"
  body = {
    properties = {
      model = {
        format  = each.value.model.format
        name    = each.value.model.name
        version = each.value.model.version
      }
      raiPolicyName        = each.value.rai_policy_name
      versionUpgradeOption = each.value.version_upgrade_option
    }
    sku = {
      name     = each.value.scale.type
      capacity = each.value.scale.capacity
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.ai_foundry,
    azapi_resource_action.foundry_cmk,
    azapi_resource_action.byor_cmk
  ]
}

resource "azurerm_private_endpoint" "ai_foundry" {
  count = var.create_private_endpoints ? 1 : 0

  location            = var.location
  name                = "pe-${azapi_resource.ai_foundry.name}"
  resource_group_name = basename(var.resource_group_resource_id)
  subnet_id           = var.private_endpoint_subnet_resource_id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "psc-${azapi_resource.ai_foundry.name}"
    private_connection_resource_id = azapi_resource.ai_foundry.id
    subresource_names              = ["account"]
  }
  private_dns_zone_group {
    name                 = "pe-${azapi_resource.ai_foundry.name}-dns"
    private_dns_zone_ids = var.ai_foundry.private_dns_zone_resource_ids
  }

  depends_on = [azapi_resource.ai_foundry]
}

resource "azurerm_role_assignment" "foundry_role_assignments" {
  for_each = local.foundry_role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = resource.azapi_resource.ai_foundry.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azapi_resource_action" "foundry_cmk" {
  count = var.ai_foundry.customer_managed_key != null ? 1 : 0

  method      = "PATCH"
  resource_id = azapi_resource.ai_foundry.id
  type        = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  body = {
    properties = {
      encryption = {
        keySource = "Microsoft.KeyVault"
        keyVaultProperties = {
          keyName          = var.ai_foundry.customer_managed_key.key_name
          keyVersion       = coalesce(var.ai_foundry.customer_managed_key.key_version, data.azurerm_key_vault_key.foundry[0].version)
          keyVaultUri      = "https://${basename(var.ai_foundry.customer_managed_key.key_vault_resource_id)}.vault.azure.net/keys/${var.ai_foundry.customer_managed_key.key_name}/${coalesce(var.ai_foundry.customer_managed_key.key_version, data.azurerm_key_vault_key.foundry[0].version)}"
          identityClientId = try(data.azurerm_user_assigned_identity.foundry[0].client_id, null)
        }
      }
    }
  }

  timeouts {
    create = "30m"
    update = "30m"
  }

  depends_on = [
    azapi_resource.ai_foundry,
    data.azurerm_key_vault_key.foundry
  ]
}

resource "azapi_resource_action" "byor_cmk" {
  count = var.create_byor_cmk && length(var.ai_foundry.managed_identities.user_assigned_resource_ids) > 0 ? 1 : 0

  method      = "PATCH"
  resource_id = azapi_resource.ai_foundry.id
  type        = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  body = {
    properties = {
      encryption = {
        keySource = "Microsoft.KeyVault"
        keyVaultProperties = {
          keyName     = "cmk"
          keyVersion  = data.azurerm_key_vault_key.byor[0].version
          keyVaultUri = "https://${replace(basename(try(module.key_vault.resource_id, values({ for k, v in module.key_vault : k => v.resource_id })[0])), "/", "")}.vault.azure.net"
          # Use the client ID from the user-assigned identity
          identityClientId = data.azurerm_user_assigned_identity.byor[0].client_id
        }
      }
    }
  }

  timeouts {
    create = "30m"
    update = "30m"
  }

  depends_on = [
    azapi_resource.ai_foundry,
    data.azurerm_key_vault_key.byor,
    data.azurerm_user_assigned_identity.byor
  ]
}

