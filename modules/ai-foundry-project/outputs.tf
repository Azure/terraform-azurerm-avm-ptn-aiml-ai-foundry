output "ai_agent_capability_host_id" {
  value       = var.create_ai_agent_service ? azapi_resource.ai_agent_capability_host[0].id : null
  description = "Resource ID of the AI agent capability host"
}

output "ai_foundry_project_id" {
  value       = var.create_ai_foundry_project ? azapi_resource.ai_foundry_project[0].id : null
  description = "Resource ID of the AI Foundry project"
}

output "ai_foundry_project_name" {
  value       = var.create_ai_foundry_project ? azapi_resource.ai_foundry_project[0].name : null
  description = "Name of the AI Foundry project"
}
