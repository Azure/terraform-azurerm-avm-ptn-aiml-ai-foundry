data "azurerm_key_vault_key" "foundry" {
  count = var.ai_foundry.customer_managed_key != null ? 1 : 0

  key_vault_id = var.ai_foundry.customer_managed_key.key_vault_resource_id
  name         = var.ai_foundry.customer_managed_key.key_name
}

data "azurerm_user_assigned_identity" "foundry" {
  count = try(var.ai_foundry.customer_managed_key.user_assigned_identity != null, false) ? 1 : 0

  #/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{userAssignedIdentityName}
  name                = reverse(split("/", var.ai_foundry.customer_managed_key.user_assigned_identity.resource_id))[0]
  resource_group_name = split("/", var.ai_foundry.customer_managed_key.user_assigned_identity.resource_id)[4]
}
