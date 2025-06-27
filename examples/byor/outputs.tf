# AI Foundry Project Outputs
output "ai_foundry_project_id" {
  description = "The resource ID of the AI Foundry Project."
  value       = module.ai_foundry.ai_foundry_project_id
}

output "ai_foundry_project_name" {
  description = "The name of the AI Foundry Project."
  value       = module.ai_foundry.ai_foundry_project_name
}

output "ai_services_name" {
  description = "The name of the AI Services account."
  value       = module.ai_foundry.ai_services_name
}

# AI Agent Service Outputs
output "ai_agent_service_id" {
  description = "The resource ID of the AI agent capability host."
  value       = module.ai_foundry.ai_agent_service_id
}

output "ai_agent_service_name" {
  description = "The name of the AI agent capability host."
  value       = module.ai_foundry.ai_agent_service_name
}

# Resource Group Information
output "resource_group_name" {
  description = "Name of the resource group used for the deployment."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Azure region where resources are deployed."
  value       = azurerm_resource_group.this.location
}

# Existing Resources Used
output "existing_storage_account_name" {
  description = "Name of the existing storage account used."
  value       = azurerm_storage_account.this.name
}

output "existing_key_vault_name" {
  description = "Name of the existing key vault used."
  value       = azurerm_key_vault.this.name
}

output "existing_cosmos_db_name" {
  description = "Name of the existing Cosmos DB account used."
  value       = azurerm_cosmosdb_account.this.name
}

output "existing_ai_search_name" {
  description = "Name of the existing AI Search service used."
  value       = azurerm_search_service.this.name
}
