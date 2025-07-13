# Data source for Key Vault when CMK is enabled
data "azurerm_key_vault" "cmk" {
  count = var.customer_managed_key != null ? 1 : 0

  name                = split("/", var.customer_managed_key.key_vault_resource_id)[8]
  resource_group_name = split("/", var.customer_managed_key.key_vault_resource_id)[4]
}

# Role assignment for AI Foundry managed identity to access the CMK
resource "azurerm_role_assignment" "cmk_crypto_user" {
  count = var.customer_managed_key != null ? 1 : 0

  scope                = var.customer_managed_key.key_vault_resource_id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = jsondecode(azapi_resource.ai_foundry.output).identity.principalId
  principal_type       = "ServicePrincipal"

  depends_on = [azapi_resource.ai_foundry]
}

resource "azapi_resource" "ai_foundry" {
  location  = var.location
  name      = var.ai_foundry_name
  parent_id = var.resource_group_id
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  body = {
    kind = var.kind
    sku = {
      name = var.sku_name
    }
    identity = {
      type = var.identity_type
      userAssignedIdentities = length(var.user_assigned_identity_ids) > 0 ? {
        for id in var.user_assigned_identity_ids : id => {}
      } : null
    }

    properties = merge({
      # Core properties
      customSubDomainName    = var.custom_sub_domain_name != null ? var.custom_sub_domain_name : var.ai_foundry_name
      disableLocalAuth       = var.disable_local_auth
      allowProjectManagement = var.allow_project_management

      # Network configuration
      publicNetworkAccess = var.public_network_access != null ? var.public_network_access : (length(var.private_endpoints) > 0 ? "Disabled" : "Enabled")
      networkAcls = {
        defaultAction = var.network_acls.default_action
        ipRules = [
          for rule in var.network_acls.ip_rules : {
            value = rule.value
          }
        ]
        virtualNetworkRules = [
          for rule in var.network_acls.virtual_network_rules : {
            id                               = rule.id
            state                           = rule.state
            ignoreMissingVnetServiceEndpoint = rule.ignoreMissingVnetServiceEndpoint
          }
        ]
      }

      # Optional properties (only include if not null)
      dynamicThrottlingEnabled       = var.dynamic_throttling_enabled
      fqdn                          = var.fqdn
      migrationToken                = var.migration_token
      restore                       = var.restore
      restrictOutboundNetworkAccess = var.restrict_outbound_network_access

      # User-owned storage
      userOwnedStorage = length(var.user_owned_storage) > 0 ? [
        for storage in var.user_owned_storage : {
          resourceId        = storage.resourceId
          identityClientId  = storage.identityClientId
          revisionId       = storage.revisionId
          subdomainName    = storage.subdomainName
        }
      ] : null

      # Quota configuration
      quotaLimit = var.quota_limit != null ? {
        count         = var.quota_limit.count
        renewalPeriod = var.quota_limit.renewalPeriod
        rules = var.quota_limit.rules != null ? [
          for rule in var.quota_limit.rules : {
            key                      = rule.key
            matchPatterns           = rule.matchPatterns
            renewalPeriod           = rule.renewalPeriod
            dynamicThrottlingEnabled = rule.dynamicThrottlingEnabled
          }
        ] : null
      } : null

      # Network injections (includes agent service if enabled)
      networkInjections = length(var.network_injections) > 0 || var.create_ai_agent_service ? concat(
        var.network_injections,
        var.create_ai_agent_service ? [{
          scenario                   = "agent"
          subnetArmId               = var.agent_subnet_id
          useMicrosoftManagedNetwork = false
        }] : []
      ) : null

      # Customer Managed Key encryption
      encryption = var.customer_managed_key != null ? {
        keySource = "Microsoft.KeyVault"
        keyVaultProperties = {
          keyName     = var.customer_managed_key.key_name
          keyVaultUri = data.azurerm_key_vault.cmk[0].vault_uri
          keyVersion  = var.customer_managed_key.key_version
        }
      } : null

    },
    # API-specific properties (only include if not empty)
    length(keys(var.api_properties)) > 0 ? var.api_properties : {}
    )
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


