output "ai_search" {
  description = "AI Search service resource object"
  value       = length(module.ai_search) > 0 ? module.ai_search[0] : null
}

output "ai_search_id" {
  description = "Resource ID of the AI Search service"
  value       = length(module.ai_search) > 0 ? module.ai_search[0].resource_id : null
}

output "ai_search_name" {
  description = "Name of the AI Search service"
  value       = length(module.ai_search) > 0 ? var.ai_search_name : null
}

output "cosmos_db" {
  description = "Cosmos DB account resource object"
  value       = length(module.cosmos_db) > 0 ? module.cosmos_db[0] : null
}

output "cosmos_db_id" {
  description = "Resource ID of the Cosmos DB account"
  value       = length(module.cosmos_db) > 0 ? module.cosmos_db[0].resource_id : null
}

output "cosmos_db_name" {
  description = "Name of the Cosmos DB account"
  value       = length(module.cosmos_db) > 0 ? var.cosmos_db_name : null
}

output "key_vault" {
  description = "Key Vault resource object"
  value       = length(module.key_vault) > 0 ? module.key_vault[0] : null
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = length(module.key_vault) > 0 ? module.key_vault[0].resource_id : null
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = length(module.key_vault) > 0 ? var.key_vault_name : null
}

output "resource_id" {
  description = "Resource ID of the primary resource (storage account if deployed, otherwise first available resource)"
  value = length(module.storage_account) > 0 ? module.storage_account[0].resource_id : (
    length(module.key_vault) > 0 ? module.key_vault[0].resource_id : (
      length(module.cosmos_db) > 0 ? module.cosmos_db[0].resource_id : (
        length(module.ai_search) > 0 ? module.ai_search[0].resource_id : null
      )
    )
  )
}

output "storage_account" {
  description = "Storage account resource object"
  value       = length(module.storage_account) > 0 ? module.storage_account[0] : null
}

output "storage_account_id" {
  description = "Resource ID of the Storage Account"
  value       = length(module.storage_account) > 0 ? module.storage_account[0].resource_id : null
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = length(module.storage_account) > 0 ? var.storage_account_name : null
}
