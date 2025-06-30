locals {
  ai_services_resource_id = var.existing_ai_services_resource_id
  base_name_storage       = substr(replace(var.base_name, "-", ""), 0, 18)
  deploy_ai_search        = var.existing_ai_search_resource_id == null
  deploy_cosmos_db        = var.existing_cosmos_db_resource_id == null
  deploy_key_vault        = var.existing_key_vault_resource_id == null
  deploy_storage_account  = var.existing_storage_account_resource_id == null
  location                = var.location
  resource_group_id       = var.create_resource_group ? azurerm_resource_group.this[0].id : data.azurerm_resource_group.existing[0].id
  resource_group_name     = coalesce(var.resource_group_name, "rg-${var.base_name}-${local.resource_token}")
  resource_names = {
    ai_agent_host                   = coalesce(var.resource_names.ai_agent_host, "ah-${var.base_name}-agent-${local.resource_token}")
    ai_foundry_project              = coalesce(var.resource_names.ai_foundry_project, "aif-${var.base_name}-proj-${local.resource_token}")
    ai_foundry_project_display_name = coalesce(var.resource_names.ai_foundry_project_display_name, "AI Foundry Project for ${var.base_name}")
    ai_search                       = coalesce(var.resource_names.ai_search, "srch-${var.base_name}-${local.resource_token}")
    ai_foundry                      = coalesce(var.resource_names.ai_foundry, "aif-${var.base_name}-${local.resource_token}")
    cosmos_db                       = coalesce(var.resource_names.cosmos_db, "cos-${var.base_name}-${local.resource_token}")
    key_vault                       = coalesce(var.resource_names.key_vault, "kv-${var.base_name}-${local.resource_token}")
    storage_account                 = coalesce(var.resource_names.storage_account, "st${local.base_name_storage}${local.resource_token}")
  }
  resource_token                     = random_string.resource_token.result
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
