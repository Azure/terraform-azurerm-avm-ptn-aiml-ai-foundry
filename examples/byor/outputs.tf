output "ai_foundry_project_id" {
  description = "The resource ID of the AI Foundry project."
  value       = module.ai_foundry.ai_foundry_project_id
}

output "ai_foundry_project_name" {
  description = "The name of the AI Foundry project."
  value       = module.ai_foundry.ai_foundry_project_name
}

output "ai_search_id" {
  description = "The resource ID of the AI Search service (BYO resource)."
  value       = module.ai_search.resource_id
}

output "ai_services" {
  description = "The AI Services account information."
  value       = module.ai_foundry.ai_services
}

output "ai_services_endpoint" {
  description = "The endpoint URL of the AI Services account."
  value       = module.ai_foundry.ai_services_endpoint
}

output "cosmos_db_id" {
  description = "The resource ID of the Cosmos DB account (BYO resource)."
  value       = module.cosmos_db.resource_id
}

output "key_vault_id" {
  description = "The resource ID of the Key Vault (BYO resource)."
  value       = module.key_vault.resource_id
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

# BYO Resource Outputs
output "storage_account_id" {
  description = "The resource ID of the storage account (BYO resource)."
  value       = module.storage_account.resource_id
}
