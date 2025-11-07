data "azurerm_key_vault_key" "byor" {
  count = var.create_byor_cmk ? 1 : 0

  key_vault_id = try(module.key_vault.resource_id, values({ for k, v in module.key_vault : k => v.resource_id })[0])
  name         = "cmk"
}

data "azurerm_user_assigned_identity" "byor" {
  count = var.create_byor_cmk && length(var.ai_foundry.managed_identities.user_assigned_resource_ids) > 0 ? 1 : 0

  name                = reverse(split("/", tolist(var.ai_foundry.managed_identities.user_assigned_resource_ids)[0]))[0]
  resource_group_name = split("/", tolist(var.ai_foundry.managed_identities.user_assigned_resource_ids)[0])[4]
}
