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

#TODO: Rewrite this to return the basename of the ai search service if a resource ID is provided, otherwise return the names (or resource id)
output "ai_search_id" {
  description = "The resource ID of the AI Search service."
  value       = try(var.ai_search_definition.existing_resource_id, null) != null ? var.ai_search_definition.existing_resource_id : module.ai_search[0].resource_id
}

output "ai_search_name" {
  description = "The name of the AI Search service."
  value       = try(var.ai_search_definition.existing_resource_id, null) != null ? basename(var.ai_search_definition.existing_resource_id) : basename(module.ai_search[0].resource_id)
}

output "cosmos_db_id" {
  description = "The resource ID of the Cosmos DB account."
  value       = try(var.cosmosdb_definition.existing_resource_id, null) != null ? var.cosmosdb_definition.existing_resource_id : module.cosmosdb[0].resource_id
}

output "cosmos_db_name" {
  description = "The name of the Cosmos DB account."
  value       = try(var.cosmosdb_definition.existing_resource_id, null) != null ? basename(var.cosmosdb_definition.existing_resource_id) : basename(module.cosmosdb[0].resource_id)
}

output "key_vault_id" {
  description = "The resource ID of the Key Vault."
  value       = try(var.key_vault_definition.existing_resource_id, null) != null ? var.key_vault_definition.existing_resource_id : module.key_vault[0].resource_id
}

output "key_vault_name" {
  description = "The name of the Key Vault."
  value       = try(var.key_vault_definition.existing_resource_id, null) != null ? basename(var.key_vault_definition.existing_resource_id) : basename(module.key_vault[0].resource_id)
}

output "project_id_guid" {
  description = "The project ID formatted as GUID for container naming (only available when AI agent service is enabled)."
  value       = module.ai_foundry_project.project_id_guid
}

output "resource_group_id" {
  description = "The resource ID of the resource group."
  value       = var.resource_group_resource_id
}

output "resource_group_name" {
  description = "The name of the resource group."
  value       = local.resource_group_name
}

output "resource_id" {
  description = "The resource ID of the primary AI Foundry project resource."
  value       = module.ai_foundry_project.ai_foundry_project_id
}

output "storage_account_id" {
  description = "The resource ID of the storage account."
  value       = try(var.storage_account_definition.existing_resource_id, null) != null ? var.storage_account_definition.existing_resource_id : module.storage_account[0].resource_id
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = try(var.storage_account_definition.existing_resource_id, null) != null ? basename(var.storage_account_definition.existing_resource_id) : basename(module.storage_account[0].resource_id)
}
