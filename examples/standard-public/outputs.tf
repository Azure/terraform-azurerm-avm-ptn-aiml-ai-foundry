# ========================================
# Basic Resource Outputs
# ========================================
output "resource_group" {
  description = "The resource group containing all AI Foundry resources."
  value       = module.ai_foundry.resource_group
}

output "location" {
  description = "The Azure region where resources are deployed."
  value       = azurerm_resource_group.this.location
}

# ========================================
# Core Service Outputs
# ========================================
output "storage_account" {
  description = "The storage account used for AI Foundry workloads."
  value       = module.ai_foundry.storage_account
}

output "key_vault" {
  description = "The Key Vault used for AI Foundry secrets management."
  value       = module.ai_foundry.key_vault
}

output "cosmos_db" {
  description = "The Cosmos DB account used for AI Foundry metadata storage."
  value       = module.ai_foundry.cosmos_db
}

output "ai_search" {
  description = "The Azure AI Search service used for intelligent search capabilities."
  value       = module.ai_foundry.ai_search
}

output "ai_services" {
  description = "The AI Services account used for AI capabilities."
  value       = module.ai_foundry.ai_services
}

# Legacy output for backward compatibility
output "cognitive_services" {
  description = "The AI Services account (legacy name for backward compatibility)."
  value       = module.ai_foundry.ai_services
}

# ========================================
# AI Foundry Outputs
# ========================================
output "ai_foundry_hub_id" {
  description = "DEPRECATED: AI Foundry Hub is no longer created. Use ai_foundry_project_id instead."
  value       = null
}

output "ai_foundry_hub_name" {
  description = "DEPRECATED: AI Foundry Hub is no longer created. Use ai_foundry_project_name instead."
  value       = null
}

output "ai_foundry_hub_workspace_url" {
  description = "DEPRECATED: AI Foundry Hub is no longer created. Use ai_foundry_project_workspace_url instead."
  value       = null
}

output "ai_foundry_project_id" {
  description = "The resource ID of the AI Foundry Project."
  value       = module.ai_foundry.ai_foundry_project_id
}

output "ai_foundry_project_name" {
  description = "The name of the AI Foundry Project."
  value       = module.ai_foundry.ai_foundry_project_name
}

output "ai_foundry_project_workspace_url" {
  description = "The discovery URL of the AI Foundry Project."
  value       = module.ai_foundry.ai_foundry_project_workspace_url
}

# ========================================
# AI Agent Service Outputs
# ========================================
output "ai_agent_service_id" {
  description = "The resource ID of the AI agent service Container App."
  value       = module.ai_foundry.ai_agent_service_id
}

output "ai_agent_service_name" {
  description = "The name of the AI agent service Container App."
  value       = module.ai_foundry.ai_agent_service_name
}

output "ai_agent_service_fqdn" {
  description = "The FQDN of the AI agent service Container App."
  value       = module.ai_foundry.ai_agent_service_fqdn
}

output "ai_agent_environment_id" {
  description = "The resource ID of the Container App Environment for AI agent services."
  value       = module.ai_foundry.ai_agent_environment_id
}

# ========================================
# Application Insights Output
# ========================================
output "application_insights" {
  description = "The Application Insights instance used for monitoring."
  sensitive   = true
  value = {
    id                  = azurerm_application_insights.this.id
    name                = azurerm_application_insights.this.name
    instrumentation_key = azurerm_application_insights.this.instrumentation_key
    connection_string   = azurerm_application_insights.this.connection_string
  }
}
