data "azurerm_key_vault_key" "byor" {
  count = var.create_byor_cmk ? 1 : 0

  key_vault_id = var.ai_foundry.customer_managed_key.key_vault_resource_id
  name         = var.ai_foundry.customer_managed_key.key_name
}
