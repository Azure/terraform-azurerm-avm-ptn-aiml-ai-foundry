data "azurerm_key_vault_key" "byor" {
  count = var.create_byor_cmk ? 1 : 0

  key_vault_id = try(module.key_vault.resource_id, values({ for k, v in module.key_vault : k => v.resource_id })[0])
  name = "cmk"
}
