resource "azapi_resource" "ai_foundry" {
  location  = var.location
  name      = var.ai_foundry_name
  parent_id = var.resource_group_id
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  body = {

    kind = "AIServices",
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      disableLocalAuth       = false
      allowProjectManagement = true
      customSubDomainName    = var.ai_foundry_name
      publicNetworkAccess    = length(var.private_endpoints) > 0 ? "Disabled" : "Enabled"
      networkAcls = {
        defaultAction       = "Allow"
        virtualNetworkRules = []
        ipRules             = []
      }

      # Enable VNet injection for Standard Agents
      networkInjections = var.create_ai_agent_service ? [
        {
          scenario                   = "agent"
          subnetArmId                = var.agent_subnet_id
          useMicrosoftManagedNetwork = false
        }
      ] : null
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


