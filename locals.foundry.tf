locals {
  # ----- AI Foundry account identity -----
  # User-assigned identities come from two sources:
  #   1. var.ai_foundry.managed_identities.user_assigned_resource_ids - explicit list
  #   2. var.ai_foundry.customer_managed_key.user_assigned_identity_resource_id - CMK requirement
  # Merge both into one set, then build the AzAPI userAssignedIdentities map.
  ai_foundry_cmk_user_assigned_identity_ids = var.ai_foundry.customer_managed_key != null ? [
    var.ai_foundry.customer_managed_key.user_assigned_identity_resource_id
  ] : []
  ai_foundry_has_system_assigned = try(var.ai_foundry.managed_identities.system_assigned, true)
  ai_foundry_has_user_assigned   = length(local.ai_foundry_user_assigned_identity_ids) > 0
  ai_foundry_identity_type = (
    local.ai_foundry_has_system_assigned && local.ai_foundry_has_user_assigned ? "SystemAssigned, UserAssigned" :
    local.ai_foundry_has_system_assigned ? "SystemAssigned" :
    local.ai_foundry_has_user_assigned ? "UserAssigned" :
    "None"
  )
  # ----- Network ACLs -----
  ai_foundry_network_acls = var.ai_foundry.network_acls == null ? {
    defaultAction       = "Allow"
    bypass              = null
    ipRules             = []
    virtualNetworkRules = []
    } : {
    defaultAction = var.ai_foundry.network_acls.default_action
    bypass        = var.ai_foundry.network_acls.bypass
    ipRules = [
      for cidr in var.ai_foundry.network_acls.ip_rules : { value = cidr }
    ]
    virtualNetworkRules = [
      for rule in var.ai_foundry.network_acls.virtual_network_rules : {
        id                               = rule.subnet_resource_id
        ignoreMissingVnetServiceEndpoint = rule.ignore_missing_vnet_service_endpoint
      }
    ]
  }
  # ----- Public network access -----
  # When the consumer does not set public_network_access_enabled, fall back to:
  #   - Disabled when create_private_endpoints = true (existing behaviour)
  #   - Enabled otherwise
  ai_foundry_public_network_access = (
    var.ai_foundry.public_network_access_enabled == null ?
    (var.create_private_endpoints ? "Disabled" : "Enabled") :
    (var.ai_foundry.public_network_access_enabled ? "Enabled" : "Disabled")
  )
  ai_foundry_user_assigned_identities = local.ai_foundry_has_user_assigned ? {
    for id in local.ai_foundry_user_assigned_identity_ids : id => {}
  } : null
  ai_foundry_user_assigned_identity_ids = toset(concat(
    tolist(var.ai_foundry.managed_identities.user_assigned_resource_ids),
    local.ai_foundry_cmk_user_assigned_identity_ids
  ))
  # Principal IDs of user-assigned identities the consumer attached to the Foundry account
  # (excluding the CMK-only identity, which does not need Cosmos/Storage data-plane access).
  ai_foundry_user_assigned_principal_ids = [
    for id in tolist(var.ai_foundry.managed_identities.user_assigned_resource_ids) :
    data.azurerm_user_assigned_identity.ai_foundry_account[id].principal_id
  ]
  foundry_default_role_assignments = {
    #holding this variable in the event we need to add static defaults in the future.
  }
  foundry_role_assignments = merge(
    local.foundry_default_role_assignments,
    var.ai_foundry.role_assignments
  )
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"
}
