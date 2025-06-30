output "ai_foundry_id" {
  description = "Resource ID of the AI Foundry account"
  value       = azapi_resource.ai_foundry.id
}

output "ai_foundry_name" {
  description = "Name of the AI Foundry account"
  value       = azapi_resource.ai_foundry.name
}

output "ai_model_deployment_ids" {
  description = "Resource IDs of the AI model deployments"
  value       = { for k, v in azapi_resource.ai_model_deployment : k => v.id }
}

output "resource_id" {
  description = "Resource ID of the primary AI Foundry account"
  value       = azapi_resource.ai_foundry.id
}
