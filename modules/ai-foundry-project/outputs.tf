output "ai_agent_capability_host_id" {
  description = "Resource ID of the AI agent capability host"
  value       = var.create_ai_agent_service && var.create_project_connections ? azapi_resource.ai_agent_capability_host[0].id : null
}

output "ai_foundry_project_id" {
  description = "Resource ID of the AI Foundry project"
  value       = azapi_resource.ai_foundry_project.id
}

output "ai_foundry_project_internal_id" {
  description = "Internal ID of the AI Foundry project used for container naming"
  value       = azapi_resource.ai_foundry_project.output.properties.internalId
}

output "ai_foundry_project_name" {
  description = "Name of the AI Foundry project"
  value       = azapi_resource.ai_foundry_project.name
}

output "ai_foundry_project_system_identity_principal_id" {
  description = "Principal ID of the AI Foundry project's system-assigned managed identity"
  value       = try(azapi_resource.ai_foundry_project.output.identity.principalId, null)
}

output "project_id_guid" {
  description = "Project ID formatted as GUID for container naming (only available when AI agent service is enabled)"
  value       = var.create_ai_agent_service ? local.project_id_guid : null
}

output "resource_id" {
  description = "Resource ID of the primary AI Foundry project"
  value       = azapi_resource.ai_foundry_project.id
}

output "role_assignments" {
  description = "Consumer-configured project role assignments keyed by the input map key, including their resource ID, scope, principal object ID, and resolved role definition ID."
  value = {
    for key, assignment in azapi_resource.role_assignments : key => {
      resource_id        = assignment.id
      scope              = assignment.parent_id
      principal_id       = assignment.body.properties.principalId
      role_definition_id = assignment.body.properties.roleDefinitionId
    }
  }
}

output "user_assigned_identity_resource_ids" {
  description = "User-assigned managed identity resource IDs attached to the AI Foundry project."
  value       = try(toset(keys(azapi_resource.ai_foundry_project.output.identity.userAssignedIdentities)), toset([]))
}
