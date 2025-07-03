output "ai_agent_capability_host_id" {
  description = "Resource ID of the AI agent capability host"
  value       = var.create_ai_agent_service ? azapi_resource.ai_agent_capability_host[0].id : null
}

output "ai_foundry_project_id" {
  description = "Resource ID of the AI Foundry project"
  value       = azapi_resource.ai_foundry_project.id
}

output "ai_foundry_project_name" {
  description = "Name of the AI Foundry project"
  value       = azapi_resource.ai_foundry_project.name
}

output "resource_id" {
  description = "Resource ID of the primary AI Foundry project"
  value       = azapi_resource.ai_foundry_project.id
}
