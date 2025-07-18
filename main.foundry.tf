resource "azapi_resource" "ai_foundry" {
  location  = var.location
  name      = local.ai_foundry_name
  parent_id = var.resource_group_resource_id
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  body = {

    kind = "AIServices",
    sku = {
      name = var.ai_foundry.sku
    }
    identity = {
      type = "SystemAssigned"
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
  schema_validation_enabled = false
  tags                      = var.tags
}


resource "azapi_resource" "ai_model_deployment" {
  for_each = var.ai_model_deployments

  name      = each.value.name
  parent_id = azapi_resource.ai_foundry.id
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-06-01"
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

  depends_on = [azapi_resource.ai_foundry]
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
    private_dns_zone_ids = [var.ai_foundry.private_dns_zone_resource_id]
  }

  depends_on = [azapi_resource.ai_foundry]
}
