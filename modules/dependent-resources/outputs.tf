output "ai_search" {
  value = length(module.ai_search) > 0 ? module.ai_search[0] : null
}

output "ai_search_id" {
  value = length(module.ai_search) > 0 ? module.ai_search[0].resource_id : null
}

output "ai_search_name" {
  value = length(module.ai_search) > 0 ? var.ai_search_name : null
}

output "cosmos_db" {
  value = length(module.cosmos_db) > 0 ? module.cosmos_db[0] : null
}

output "cosmos_db_id" {
  value = length(module.cosmos_db) > 0 ? module.cosmos_db[0].resource_id : null
}

output "cosmos_db_name" {
  value = length(module.cosmos_db) > 0 ? var.cosmos_db_name : null
}

output "key_vault" {
  value = length(module.key_vault) > 0 ? module.key_vault[0] : null
}

output "key_vault_id" {
  value = length(module.key_vault) > 0 ? module.key_vault[0].resource_id : null
}

output "key_vault_name" {
  value = length(module.key_vault) > 0 ? var.key_vault_name : null
}

output "storage_account" {
  value = length(module.storage_account) > 0 ? module.storage_account[0] : null
}

output "storage_account_id" {
  value = length(module.storage_account) > 0 ? module.storage_account[0].resource_id : null
}

output "storage_account_name" {
  value = length(module.storage_account) > 0 ? var.storage_account_name : null
}
