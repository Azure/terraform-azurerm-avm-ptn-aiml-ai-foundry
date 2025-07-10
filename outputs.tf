output "ai_agent_service_id" {
  description = "The resource ID of the AI agent capability host."
  value       = length(local.projects) == 1 ? values(module.ai_foundry_project)[0].ai_agent_capability_host_id : module.ai_foundry_project["default"].ai_agent_capability_host_id
}

output "ai_agent_service_ids" {
  description = "Map of project names to their AI agent capability host resource IDs."
  value       = { for k, v in module.ai_foundry_project : k => v.ai_agent_capability_host_id }
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
  value       = length(local.projects) == 1 ? values(module.ai_foundry_project)[0].ai_foundry_project_id : module.ai_foundry_project["default"].ai_foundry_project_id
}

output "ai_foundry_project_ids" {
  description = "Map of project names to their AI Foundry Project resource IDs."
  value       = { for k, v in module.ai_foundry_project : k => v.ai_foundry_project_id }
}

output "ai_foundry_project_internal_id" {
  description = "The internal ID of the AI Foundry project used for container naming."
  value       = length(local.projects) == 1 ? values(module.ai_foundry_project)[0].ai_foundry_project_internal_id : module.ai_foundry_project["default"].ai_foundry_project_internal_id
}

output "ai_foundry_project_internal_ids" {
  description = "Map of project names to their internal IDs used for container naming."
  value       = { for k, v in module.ai_foundry_project : k => v.ai_foundry_project_internal_id }
}

output "ai_foundry_project_name" {
  description = "The name of the AI Foundry Project."
  value       = length(local.projects) == 1 ? values(module.ai_foundry_project)[0].ai_foundry_project_name : module.ai_foundry_project["default"].ai_foundry_project_name
}

output "ai_foundry_project_names" {
  description = "Map of project keys to their AI Foundry Project names."
  value       = { for k, v in module.ai_foundry_project : k => v.ai_foundry_project_name }
}

output "ai_foundry_project_system_identity_principal_id" {
  description = "The principal ID of the AI Foundry project's system-assigned managed identity."
  value       = length(local.projects) == 1 ? values(module.ai_foundry_project)[0].ai_foundry_project_system_identity_principal_id : module.ai_foundry_project["default"].ai_foundry_project_system_identity_principal_id
}

output "ai_foundry_project_system_identity_principal_ids" {
  description = "Map of project names to their system-assigned managed identity principal IDs."
  value       = { for k, v in module.ai_foundry_project : k => v.ai_foundry_project_system_identity_principal_id }
}

output "ai_model_deployment_ids" {
  description = "The resource IDs of all AI model deployments."
  value       = module.ai_foundry.ai_model_deployment_ids
}

output "ai_search_id" {
  description = "The resource ID of the AI Search service."
  value       = module.dependent_resources.ai_search_id
}

output "ai_search_name" {
  description = "The name of the AI Search service."
  value       = module.dependent_resources.ai_search_name
}

output "cosmos_db_id" {
  description = "The resource ID of the Cosmos DB account."
  value       = module.dependent_resources.cosmos_db_id
}

output "cosmos_db_name" {
  description = "The name of the Cosmos DB account."
  value       = module.dependent_resources.cosmos_db_name
}

output "key_vault_id" {
  description = "The resource ID of the Key Vault."
  value       = module.dependent_resources.key_vault_id
}

output "key_vault_name" {
  description = "The name of the Key Vault."
  value       = module.dependent_resources.key_vault_name
}

output "project_id_guid" {
  description = "The project ID formatted as GUID for container naming (only available when AI agent service is enabled)."
  value       = length(local.projects) == 1 ? values(module.ai_foundry_project)[0].project_id_guid : module.ai_foundry_project["default"].project_id_guid
}

output "project_id_guids" {
  description = "Map of project names to their project IDs formatted as GUIDs for container naming."
  value       = { for k, v in module.ai_foundry_project : k => v.project_id_guid }
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
  value       = length(local.projects) == 1 ? values(module.ai_foundry_project)[0].ai_foundry_project_id : module.ai_foundry_project["default"].ai_foundry_project_id
}

output "resource_ids" {
  description = "Map of project names to their AI Foundry project resource IDs."
  value       = { for k, v in module.ai_foundry_project : k => v.ai_foundry_project_id }
}

output "storage_account_id" {
  description = "The resource ID of the storage account."
  value       = module.dependent_resources.storage_account_id
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = module.dependent_resources.storage_account_name
}
