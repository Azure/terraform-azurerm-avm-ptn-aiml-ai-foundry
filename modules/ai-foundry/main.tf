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
      publicNetworkAccess    = var.private_endpoint_subnet_id == null ? "Enabled" : "Disabled"
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
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  location            = var.location
  name                = "pe-${azapi_resource.ai_foundry.name}"
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "psc-${azapi_resource.ai_foundry.name}"
    private_connection_resource_id = azapi_resource.ai_foundry.id
    subresource_names              = ["account"]
  }
  private_dns_zone_group {
    name                 = "pe-${azapi_resource.ai_foundry.name}-dns"
    private_dns_zone_ids = [var.private_dns_zone_resource_id_ai_foundry]
  }

  depends_on = [azapi_resource.ai_foundry]
}
