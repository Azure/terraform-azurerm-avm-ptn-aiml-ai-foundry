# Data sources for existing resources and client config
data "azurerm_client_config" "current" {}

data "azurerm_storage_account" "existing" {
  count = var.existing_storage_account_resource_id != null ? 1 : 0

  name                = split("/", var.existing_storage_account_resource_id)[8]
  resource_group_name = split("/", var.existing_storage_account_resource_id)[4]
}

data "azurerm_key_vault" "existing" {
  count = var.existing_key_vault_resource_id != null ? 1 : 0

  name                = split("/", var.existing_key_vault_resource_id)[8]
  resource_group_name = split("/", var.existing_key_vault_resource_id)[4]
}

data "azurerm_cosmosdb_account" "existing" {
  count = var.existing_cosmos_db_resource_id != null ? 1 : 0

  name                = split("/", var.existing_cosmos_db_resource_id)[8]
  resource_group_name = split("/", var.existing_cosmos_db_resource_id)[4]
}

data "azurerm_search_service" "existing" {
  count = var.existing_ai_search_resource_id != null ? 1 : 0

  name                = split("/", var.existing_ai_search_resource_id)[8]
  resource_group_name = split("/", var.existing_ai_search_resource_id)[4]
}
