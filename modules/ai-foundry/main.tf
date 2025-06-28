resource "azapi_resource" "ai_foundry" {
  location  = var.location
  name      = var.ai_foundry_name
  parent_id = var.resource_group_id
  type      = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      publicNetworkAccess    = length(var.ai_foundry_private_endpoints) == 0 ? "Enabled" : "Disabled"
      allowProjectManagement = true
      customSubDomainName    = var.ai_foundry_name
    }
  }

  tags = var.tags

  identity {
    type = "SystemAssigned"
  }
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

  depends_on = [azapi_resource.ai_foundry]
}

resource "azurerm_private_endpoint" "ai_foundry" {
  for_each = var.ai_foundry_private_endpoints

  location            = each.value.location != null ? each.value.location : var.location
  name                = each.value.name != null ? each.value.name : "pe-${azapi_resource.ai_foundry.name}-${each.key}"
  resource_group_name = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id           = each.value.subnet_resource_id
  tags                = merge(var.tags, each.value.tags)

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "psc-${azapi_resource.ai_foundry.name}-${each.key}"
    private_connection_resource_id = azapi_resource.ai_foundry.id
    subresource_names              = [each.value.subresource_name]
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? [each.value.private_dns_zone_group_name] : []
    content {
      name                 = private_dns_zone_group.value
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }

  depends_on = [azapi_resource.ai_foundry]
}
