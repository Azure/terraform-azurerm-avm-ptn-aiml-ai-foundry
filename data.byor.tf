data "azurerm_key_vault_key" "byor" {
  count = var.create_byor_cmk ? 1 : 0

  # module.key_vault uses for_each in BYOR mode, so its outputs are maps. Convert to a single string.
  # We assume one BYOR Key Vault for CMK. Taking the first value is sufficient.
  key_vault_id = values(module.key_vault.resource_id)[0]
  # We create the key with name "cmk" in main.byor.tf inputs to the Key Vault module.
  name = "cmk"
}
