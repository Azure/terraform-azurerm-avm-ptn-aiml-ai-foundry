# Example outputs for the AI Foundry Pattern module
output "resource_group" {
  description = "Information about the created resource group"
  value       = module.ai_foundry.resource_group
}

output "storage_account" {
  description = "Information about the storage account used for AI workloads"
  value       = module.ai_foundry.storage_account
}

output "key_vault" {
  description = "Information about the Key Vault used for secrets management"
  value       = module.ai_foundry.key_vault
}

output "cosmos_db" {
  description = "Information about the Cosmos DB account"
  value       = module.ai_foundry.cosmos_db
}

output "ai_search" {
  description = "Information about the AI Search service"
  value       = module.ai_foundry.ai_search
}

output "cognitive_services" {
  description = "Information about the Cognitive Services account with OpenAI"
  value       = module.ai_foundry.cognitive_services
}

output "private_endpoints" {
  description = "Information about all private endpoints"
  value       = module.ai_foundry.private_endpoints
}

output "connection_info" {
  description = "Connection information for all AI Foundry services"
  value       = module.ai_foundry.connection_info
  sensitive   = true
}

output "managed_identities" {
  description = "Managed identities created for the services"
  value       = module.ai_foundry.managed_identities
}
