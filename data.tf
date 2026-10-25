# Look up principal IDs for user-assigned managed identities the consumer attached to the
# AI Foundry account. Excludes the CMK identity which is handled separately (CMK does not
# need data-plane access on Cosmos/Storage).
data "azurerm_user_assigned_identity" "ai_foundry_account" {
  for_each = toset(tolist(var.ai_foundry.managed_identities.user_assigned_resource_ids))

  name                = split("/", each.value)[8]
  resource_group_name = split("/", each.value)[4]
}

data "azapi_resource" "ai_foundry_account_keyed" {
  for_each = var.ai_foundry.user_assigned_identities

  resource_id            = each.value
  type                   = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  response_export_values = ["properties.principalId"]
}
