locals {
  base_name_storage = substr(replace(var.base_name, "-", ""), 0, 18)
  location          = var.location
  resource_names = {
    ai_agent_host                   = coalesce(var.resource_names.ai_agent_host, "ah${var.base_name}agent${local.resource_token}")
    ai_foundry_project              = coalesce(var.resource_names.ai_foundry_project, "aif-${var.base_name}-proj-${local.resource_token}")
    ai_foundry_project_display_name = coalesce(var.resource_names.ai_foundry_project_display_name, "AI Foundry Project for ${var.base_name}")
    ai_foundry                      = coalesce(var.resource_names.ai_foundry, "aif-${var.base_name}-${local.resource_token}")
  }
  resource_token                     = random_string.resource_token.result
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
