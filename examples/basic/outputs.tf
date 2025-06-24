output "resource_group" {
  description = "The resource group information."
  value = {
    id       = azurerm_resource_group.this.id
    name     = azurerm_resource_group.this.name
    location = azurerm_resource_group.this.location
  }
}

# No AI Foundry Hub in new implementation
output "ai_foundry_hub" {
  description = "DEPRECATED: AI Foundry Hub is no longer created."
  value       = null
}

output "ai_foundry_project" {
  description = "The AI Foundry Project information."
  value = {
    id   = module.ai_foundry.ai_foundry_project_id
    name = module.ai_foundry.ai_foundry_project_name
    url  = module.ai_foundry.ai_foundry_project_workspace_url
  }
}

output "ai_services" {
  description = "The AI Services account information."
  value = {
    id       = module.ai_foundry.ai_services.id
    name     = module.ai_foundry.ai_services.name
    endpoint = module.ai_foundry.ai_services.endpoint
  }
}

output "storage_account" {
  description = "The storage account information."
  value       = module.ai_foundry.storage_account
}

output "key_vault" {
  description = "The Key Vault information."
  value       = module.ai_foundry.key_vault
}

output "cosmos_db" {
  description = "The Cosmos DB account information."
  value       = module.ai_foundry.cosmos_db
}

output "ai_search" {
  description = "The AI Search service information."
  value       = module.ai_foundry.ai_search
}
