# Data sources for existing resources
data "azurerm_resource_group" "existing" {
  count = var.existing_resource_group_name != null || var.existing_resource_group_id != null ? 1 : 0

  name = var.existing_resource_group_name != null ? var.existing_resource_group_name : split("/", var.existing_resource_group_id)[4]
}

data "azurerm_application_insights" "existing" {
  count = var.existing_application_insights_id != null ? 1 : 0

  name                = split("/", var.existing_application_insights_id)[8]
  resource_group_name = split("/", var.existing_application_insights_id)[4]
}

data "azurerm_log_analytics_workspace" "existing" {
  count = var.existing_log_analytics_workspace_id != null ? 1 : 0

  name                = split("/", var.existing_log_analytics_workspace_id)[8]
  resource_group_name = split("/", var.existing_log_analytics_workspace_id)[4]
}

# Data sources for optional external networking resources
data "azurerm_virtual_network" "external" {
  count = var.virtual_network_resource_id != null ? 1 : 0

  name                = split("/", var.virtual_network_resource_id)[8]
  resource_group_name = split("/", var.virtual_network_resource_id)[4]
}

data "azurerm_subnet" "external" {
  count = var.subnet_resource_id != null ? 1 : 0

  name                 = split("/", var.subnet_resource_id)[10]
  resource_group_name  = split("/", var.subnet_resource_id)[4]
  virtual_network_name = split("/", var.subnet_resource_id)[8]
}

data "azurerm_bastion_host" "external" {
  count = var.bastion_host_resource_id != null ? 1 : 0

  name                = split("/", var.bastion_host_resource_id)[8]
  resource_group_name = split("/", var.bastion_host_resource_id)[4]
}

data "azurerm_virtual_machine" "external" {
  count = var.virtual_machine_resource_id != null ? 1 : 0

  name                = split("/", var.virtual_machine_resource_id)[8]
  resource_group_name = split("/", var.virtual_machine_resource_id)[4]
}

# Deprecated - maintain backward compatibility
data "azurerm_virtual_network" "existing" {
  count = var.existing_virtual_network_id != null ? 1 : 0

  name                = split("/", var.existing_virtual_network_id)[8]
  resource_group_name = split("/", var.existing_virtual_network_id)[4]
}

data "azurerm_subnet" "existing" {
  count = var.existing_subnet_id != null ? 1 : 0

  name                 = split("/", var.existing_subnet_id)[10]
  resource_group_name  = split("/", var.existing_subnet_id)[4]
  virtual_network_name = split("/", var.existing_subnet_id)[8]
}

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
