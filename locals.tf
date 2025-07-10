locals {
  base_name_storage = substr(replace(var.base_name, "-", ""), 0, 18)
  location          = var.location
  resource_group_id = coalesce(
    var.resource_group_id,
    var.create_resource_group ? azurerm_resource_group.this[0].id : "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.resource_group_name_safe}"
  )
  resource_group_name = local.resource_group_name_safe
  # Ensure resource_group_name is never null before using in string interpolation
  resource_group_name_safe = coalesce(var.resource_group_name, "rg-${var.base_name}-${local.resource_token}")
  
  # Create projects map - handles both old single project and new multiple projects approach
  projects = length(var.ai_services_projects) > 0 ? var.ai_services_projects : {
    "default" = {
      description  = var.ai_foundry_project_description
      display_name = coalesce(var.resource_names.ai_foundry_project_display_name, "AI Foundry Project for ${var.base_name}")
    }
  }
  
  resource_names = {
    ai_agent_host                   = coalesce(var.resource_names.ai_agent_host, "ah${var.base_name}agent${local.resource_token}")
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
