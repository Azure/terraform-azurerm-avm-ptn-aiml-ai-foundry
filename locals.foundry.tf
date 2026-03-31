locals {
  foundry_default_role_assignments = {
    #holding this variable in the event we need to add static defaults in the future.
  }
  foundry_role_assignments = merge(
    local.foundry_default_role_assignments,
    var.ai_foundry.role_assignments
  )
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"
}

# Managed identity locals
locals {
  cmk_uami = var.ai_foundry.customer_managed_key != null ? {
    (var.ai_foundry.customer_managed_key.user_assigned_identity_resource_id) = {}
  } : null
  uses_uami = length(var.ai_foundry.managed_identities.user_assigned_resource_ids) > 0 || locals.cmk_uami != null
  system_assigned_user_assigned = (var.ai_foundry.managed_identities.system_assigned || locals.uses_uami) ? {
    this = {
      type                       = var.ai_foundry.managed_identities.system_assigned && locals.uses_uami ? "SystemAssigned, UserAssigned" : locals.uses_uami ? "UserAssigned" : "SystemAssigned"
      user_assigned_resource_ids = locals.uses_uami ? merge(var.ai_foundry.managed_identities.user_assigned_resource_ids, locals.cmk_uami) : null
    }
  } : {}
}
