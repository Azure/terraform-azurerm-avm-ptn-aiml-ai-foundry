locals {
  foundry_default_role_assignments = {
    deployment_user_cognitive_services_user = {
      role_definition_id_or_name             = "Cognitive Services User"
      principal_id                           = data.azurerm_client_config.current.object_id
      condition                              = null
      condition_version                      = null
      skip_service_principal_aad_check       = false
      delegated_managed_identity_resource_id = null
      principal_type                         = null
    }
  }
  foundry_role_assignments = merge(
    local.foundry_default_role_assignments,
    var.ai_foundry.role_assignments
  )
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"
}
