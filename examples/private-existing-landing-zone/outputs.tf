output "resource_group_name" {
  description = "Name of the resource group hosting the AI Foundry workload."
  value       = local.resource_group_name
}

output "resource_group_resource_id" {
  description = "Resource ID of the resource group hosting the AI Foundry workload."
  value       = local.resource_group_resource_id
}

output "ai_foundry_name" {
  description = "Name of the AI Foundry (Cognitive Services) account."
  value       = module.ai_foundry.ai_foundry_name
}

output "ai_foundry_id" {
  description = "Resource ID of the AI Foundry account."
  value       = module.ai_foundry.ai_foundry_id
}

output "ai_foundry_project_ids" {
  description = "Resource IDs of the AI Foundry projects."
  value       = module.ai_foundry.ai_foundry_project_id
}

output "ai_foundry_project_names" {
  description = "Names of the AI Foundry projects."
  value       = module.ai_foundry.ai_foundry_project_name
}

output "ai_model_deployment_ids" {
  description = "Resource IDs of the model deployments created on the AI Foundry account."
  value       = module.ai_foundry.ai_model_deployment_ids
}

output "agent_subnet_resource_id" {
  description = "Subnet used for AI Foundry Standard Agent network injection."
  value       = local.agent_subnet_resource_id
}

output "storage_account_id" {
  description = "Resource ID of the BYOR storage account."
  value       = module.storage_account.resource_id
}

output "cosmosdb_id" {
  description = "Resource ID of the BYOR Cosmos DB account."
  value       = module.cosmosdb.resource_id
}

output "ai_search_id" {
  description = "Resource ID of the BYOR Azure AI Search service."
  value       = azapi_resource.ai_search.id
}

output "key_vault_id" {
  description = "Resource ID of the BYOR Key Vault, or null when deploy_key_vault is false."
  value       = var.deploy_key_vault ? module.key_vault[0].resource_id : null
}

output "video_indexer_id" {
  description = "Resource ID of the Azure AI Video Indexer account, or null when deploy_video_indexer is false."
  value       = var.deploy_video_indexer ? azapi_resource.video_indexer[0].id : null
}

output "video_indexer_name" {
  description = "Name of the Azure AI Video Indexer account, or null when deploy_video_indexer is false."
  value       = var.deploy_video_indexer ? local.names.video_indexer : null
}

output "video_indexer_account_id" {
  description = "Data-plane account ID of the Video Indexer account, used by the Video Indexer REST API. Null when deploy_video_indexer is false."
  value       = var.deploy_video_indexer ? try(azapi_resource.video_indexer[0].output.properties.accountId, null) : null
}

output "video_indexer_storage_account_id" {
  description = "Resource ID of the storage account dedicated to Video Indexer, or null when deploy_video_indexer is false."
  value       = var.deploy_video_indexer ? module.video_indexer_storage[0].resource_id : null
}

output "created_private_dns_zone_ids" {
  description = "Resource IDs of the private DNS zones created by this configuration, keyed by zone purpose. Empty when create_private_dns_zones is false."
  value       = { for key, zone in azurerm_private_dns_zone.this : key => zone.id }
}

output "private_dns_zone_ids_in_use" {
  description = "Private DNS zone resource IDs this configuration attached to its private endpoints. Empty values mean DNS is handled by platform policy."
  value       = local.managed_private_dns_zone_ids
}
