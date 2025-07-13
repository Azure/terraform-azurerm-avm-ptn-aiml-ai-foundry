output "ai_agent_service_id" {
  description = "The resource ID of the AI agent capability host."
  value       = module.ai_foundry_project.ai_agent_capability_host_id
}

output "ai_foundry_id" {
  description = "The resource ID of the AI Foundry account."
  value       = module.ai_foundry.ai_foundry_id
}

output "ai_foundry_name" {
  description = "The name of the AI Foundry account."
  value       = module.ai_foundry.ai_foundry_name
}

output "ai_foundry_project_id" {
  description = "The resource ID of the AI Foundry Project."
  value       = module.ai_foundry_project.ai_foundry_project_id
}

output "ai_foundry_project_internal_id" {
  description = "The internal ID of the AI Foundry project used for container naming."
  value       = module.ai_foundry_project.ai_foundry_project_internal_id
}

output "ai_foundry_project_name" {
  description = "The name of the AI Foundry Project."
  value       = module.ai_foundry_project.ai_foundry_project_name
}

output "ai_foundry_project_system_identity_principal_id" {
  description = "The principal ID of the AI Foundry project's system-assigned managed identity."
  value       = module.ai_foundry_project.ai_foundry_project_system_identity_principal_id
}

output "ai_model_deployment_ids" {
  description = "The resource IDs of all AI model deployments."
  value       = module.ai_foundry.ai_model_deployment_ids
}

output "project_id_guid" {
  description = "The project ID formatted as GUID for container naming (only available when AI agent service is enabled)."
  value       = module.ai_foundry_project.project_id_guid
}

output "resource_group_id" {
  description = "The resource ID of the resource group."
  value       = local.resource_group_id
}

output "resource_group_name" {
  description = "The name of the resource group."
  value       = local.resource_group_name
}

output "resource_id" {
  description = "The resource ID of the primary AI Foundry project resource."
  value       = module.ai_foundry_project.ai_foundry_project_id
}
