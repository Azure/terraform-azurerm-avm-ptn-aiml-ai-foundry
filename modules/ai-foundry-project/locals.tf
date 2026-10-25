locals {
  project_principal_ids = merge(
    var.managed_identities.system_assigned ? { system_assigned = azapi_resource.ai_foundry_project.output.identity.principalId } : {},
    {
      for key, identity in data.azapi_resource.project_user_assigned_identity :
      key => identity.output.properties.principalId
    }
  )
  project_connection_roles = {
    for entry in flatten([
      for identity_key, principal_id in local.project_principal_ids : [
        for role_key, role in merge(local.ai_search_default_role_assignments, local.cosmosdb_default_role_assignments, local.storage_account_default_role_assignments) : {
          key          = identity_key == "system_assigned" ? role_key : "${identity_key}:${role_key}"
          principal_id = principal_id
          role_key     = role_key
          role_name    = role.role_definition_id_or_name
        }
      ]
    ]) : entry.key => entry
  }
  project_user_assigned_identity_ids = concat(tolist(var.managed_identities.user_assigned_resource_ids), values(var.user_assigned_identities))
  project_user_assigned_identities = length(local.project_user_assigned_identity_ids) > 0 ? {
    for id in local.project_user_assigned_identity_ids : id => {}
  } : null
  project_identity_type = (
    var.managed_identities.system_assigned && length(local.project_user_assigned_identity_ids) > 0 ? "SystemAssigned, UserAssigned" :
    var.managed_identities.system_assigned ? "SystemAssigned" :
    length(local.project_user_assigned_identity_ids) > 0 ? "UserAssigned" :
    "None"
  )

  # Extract project internal ID and format as GUID for container naming.
  project_id_guid = var.create_ai_agent_service ? "${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 0, 8)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 8, 4)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 12, 4)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 16, 4)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 20, 12)}" : ""
}
