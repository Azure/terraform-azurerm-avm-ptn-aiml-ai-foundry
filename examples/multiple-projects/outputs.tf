output "ai_foundry_id" {
  description = "The resource ID of the AI Foundry account."
  value       = module.ai_foundry.ai_foundry_id
}

output "ai_foundry_project_ids" {
  description = "Map of project names to their AI Foundry Project resource IDs."
  value       = module.ai_foundry.ai_foundry_project_ids
}

output "ai_foundry_project_names" {
  description = "Map of project keys to their AI Foundry Project names."
  value       = module.ai_foundry.ai_foundry_project_names
}

output "resource_group_id" {
  description = "The resource ID of the resource group."
  value       = module.ai_foundry.resource_group_id
}