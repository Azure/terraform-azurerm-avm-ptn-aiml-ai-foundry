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

output "ai_foundry_project_name" {
  description = "The name of the AI Foundry Project."
  value       = module.ai_foundry_project.ai_foundry_project_name
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

output "storage_account_id" {
  description = "The resource ID of the storage account."
  value       = module.dependent_resources.storage_account_id
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = module.dependent_resources.storage_account_name
}
