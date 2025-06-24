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
# Networking Outputs
# ========================================
output "virtual_network" {
  description = "The virtual network created for private endpoint connectivity."
  value = {
    id                = azurerm_virtual_network.this.id
    name              = azurerm_virtual_network.this.name
    address_space     = azurerm_virtual_network.this.address_space
    subnet_ids        = {
      private_endpoints = azurerm_subnet.private_endpoints.id
      agent_services    = azurerm_subnet.agent_services.id
    }
  }
}

output "private_dns_zones" {
  description = "The private DNS zones created for private endpoint connectivity."
  value = {
    storage_blob   = {
      id   = azurerm_private_dns_zone.storage_blob.id
      name = azurerm_private_dns_zone.storage_blob.name
    }
    keyvault       = {
      id   = azurerm_private_dns_zone.keyvault.id
      name = azurerm_private_dns_zone.keyvault.name
    }
    cosmosdb       = {
      id   = azurerm_private_dns_zone.cosmosdb.id
      name = azurerm_private_dns_zone.cosmosdb.name
    }
    search         = {
      id   = azurerm_private_dns_zone.search.id
      name = azurerm_private_dns_zone.search.name
    }
    openai         = {
      id   = azurerm_private_dns_zone.openai.id
      name = azurerm_private_dns_zone.openai.name
    }
    ml_workspace   = {
      id   = azurerm_private_dns_zone.ml_workspace.id
      name = azurerm_private_dns_zone.ml_workspace.name
    }
  }
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
  description = "The resource ID of the AI Foundry Hub."
  value       = module.ai_foundry.ai_foundry_hub_id
}

output "ai_foundry_hub_name" {
  description = "The name of the AI Foundry Hub."
  value       = module.ai_foundry.ai_foundry_hub_name
}

output "ai_foundry_hub_workspace_url" {
  description = "The discovery URL of the AI Foundry Hub."
  value       = module.ai_foundry.ai_foundry_hub_workspace_url
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
# Private Endpoint Outputs
# ========================================
output "ai_foundry_hub_private_endpoints" {
  description = "A map of private endpoints created for the AI Foundry Hub."
  value       = module.ai_foundry.ai_foundry_hub_private_endpoints
}

output "ai_foundry_project_private_endpoints" {
  description = "A map of private endpoints created for the AI Foundry Project."
  value       = module.ai_foundry.ai_foundry_project_private_endpoints
}

# ========================================
# Application Insights Output
# ========================================
output "application_insights" {
  description = "The Application Insights instance used for monitoring."
  value = {
    id                     = azurerm_application_insights.this.id
    name                   = azurerm_application_insights.this.name
    instrumentation_key    = azurerm_application_insights.this.instrumentation_key
    connection_string      = azurerm_application_insights.this.connection_string
  }
}
