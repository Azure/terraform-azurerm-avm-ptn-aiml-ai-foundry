locals {
  deploy_ai_search       = var.existing_ai_search_resource_id == null
  deploy_cosmos_db       = var.existing_cosmos_db_resource_id == null
  deploy_key_vault       = var.existing_key_vault_resource_id == null
  deploy_storage_account = var.existing_storage_account_resource_id == null

  location            = var.location
  resource_group_id   = azurerm_resource_group.this.id
  resource_group_name = var.resource_group_name
  resource_token      = random_string.resource_token.result

  resource_names = {
    ai_agent_host = coalesce(
      var.resource_names.ai_agent_host,
      var.ai_agent_host_name,
      var.base_name != null ? "${var.base_name}-agent-${local.resource_token}" : null,
      "${substr(replace(var.name, "-", ""), 0, 10)}-agent-${local.resource_token}"
    )
    ai_foundry_project = coalesce(
      var.resource_names.ai_foundry_project,
      var.ai_foundry_project_name,
      var.base_name != null ? "${var.base_name}-proj" : null,
      "${substr(replace(var.name, "-", ""), 0, 15)}-proj"
    )
    ai_search = coalesce(
      var.resource_names.ai_search,
      var.base_name != null ? "srch-${var.base_name}-${local.resource_token}" : null,
      "srch-${substr(replace(var.name, "-", ""), 0, 10)}-${local.resource_token}"
    )
    ai_foundry = coalesce(
      var.resource_names.ai_foundry,
      var.base_name != null ? "${var.base_name}-ai-${local.resource_token}" : null,
      "${substr(replace(var.name, "-", ""), 0, 10)}-ai-${local.resource_token}"
    )
    cosmos_db = coalesce(
      var.resource_names.cosmos_db,
      var.base_name != null ? "cos-${var.base_name}-${local.resource_token}" : null,
      "cos-${substr(replace(var.name, "-", ""), 0, 10)}-${local.resource_token}"
    )
    key_vault = coalesce(
      var.resource_names.key_vault,
      var.base_name != null ? "kv-${var.base_name}-${local.resource_token}" : null,
      "kv-${substr(replace(var.name, "-", ""), 0, 13)}-${local.resource_token}"
    )
    storage_account = coalesce(
      var.resource_names.storage_account,
      var.base_name != null ? "st${var.base_name}${local.resource_token}" : null,
      "st${substr(replace(var.name, "-", ""), 0, 15)}${local.resource_token}"
    )
  }

  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"

  storage_connections = var.existing_storage_account_resource_id != null && var.existing_storage_account_resource_id != "skip-deployment" ? [
    var.existing_storage_account_resource_id
    ] : local.deploy_storage_account ? [
    local.resource_names.storage_account
  ] : []

  thread_storage_connections = var.existing_storage_account_resource_id != null && var.existing_storage_account_resource_id != "skip-deployment" ? [
    var.existing_storage_account_resource_id
    ] : local.deploy_storage_account ? [
    local.resource_names.storage_account
  ] : []

  vector_store_connections = var.existing_ai_search_resource_id != null && var.existing_ai_search_resource_id != "skip-deployment" ? [
    var.existing_ai_search_resource_id
    ] : local.deploy_ai_search ? [
    local.resource_names.ai_search
  ] : []
}
