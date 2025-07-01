locals {
  base_name_storage      = substr(replace(var.base_name, "-", ""), 0, 18)
  deploy_ai_search       = var.existing_ai_search_resource_id != null ? true : false
  deploy_cosmos_db       = var.existing_cosmos_db_resource_id != null ? true : false
  deploy_key_vault       = var.existing_key_vault_resource_id != null ? true : false
  deploy_storage_account = var.existing_storage_account_resource_id != null ? true : false
  location               = var.location
  # Resource Group ID priority:
  # 1. If var.resource_group_id is provided, use it (for cross-subscription or explicit scenarios)
  # 2. If creating resource group, use the created resource group ID
  # 3. Otherwise, construct the ID from current subscription and provided resource group name
  resource_group_id = coalesce(
    var.resource_group_id,
    var.create_resource_group ? azurerm_resource_group.this[0].id : "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  )
  resource_group_name = coalesce(var.resource_group_name, "rg-${var.base_name}-${local.resource_token}")
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
}
