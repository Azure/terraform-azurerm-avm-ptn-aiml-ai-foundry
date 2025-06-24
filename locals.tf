# AI Foundry Pattern Module Locals
locals {
  # Managed identities configuration
  managed_identities = {
    system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }

  # Resource naming with random suffix
  resource_suffix = random_string.suffix.result

  # AI Foundry project name
  ai_foundry_project_name = var.ai_foundry_project_name != null ? var.ai_foundry_project_name : "${var.name}-ai-foundry"

  # Role definition resource substring for role assignments
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"

  # Common tags for all resources
  common_tags = merge(var.tags, {
    "ai-foundry-pattern" = "true"
    "deployment-type"    = "avm-pattern"
  })
}
