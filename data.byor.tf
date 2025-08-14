data "azurerm_key_vault_key" "byor" {
  count = var.create_byor_cmk ? 1 : 0

  key_vault_id = module.key_vault.resource_id
  name         = module.key_vault.keys.cmk.name
}
