output "ai_model_deployment_ids" {
  value       = { for k, v in azapi_resource.ai_model_deployment : k => v.id }
  description = "Resource IDs of the AI model deployments"
}

output "ai_foundry_id" {
  value       = azapi_resource.ai_foundry.id
  description = "Resource ID of the AI Foundry account"
}

output "ai_foundry_name" {
  value       = azapi_resource.ai_foundry.name
  description = "Name of the AI Foundry account"
}
