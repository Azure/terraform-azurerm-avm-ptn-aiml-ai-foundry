# Bicep Pattern Outputs (matching main.bicep outputs)

# Additional Bicep Pattern Outputs (new outputs only)

output "ai_agent_environment_id" {
  description = "DEPRECATED: Container App Environment is managed internally by capability host."
  value       = null
}

output "ai_agent_service_fqdn" {
  description = "The FQDN of the AI agent service (if available from capability host)."
  value       = local.deploy_ai_agent_service ? try(azapi_resource.ai_agent_capability_host[0].output.properties.fqdn, null) : null
}

# AI Agent Service Outputs
output "ai_agent_service_id" {
  description = "The resource ID of the AI agent capability host."
  value       = local.deploy_ai_agent_service ? azapi_resource.ai_agent_capability_host[0].id : null
}

output "ai_agent_service_name" {
  description = "The name of the AI agent capability host."
  value       = local.deploy_ai_agent_service ? azapi_resource.ai_agent_capability_host[0].name : null
}

# AI Foundry Outputs
# Note: AI Foundry Hub is no longer created - only Project is supported
output "ai_foundry_hub_id" {
  description = "DEPRECATED: AI Foundry Hub is no longer created. Use ai_foundry_project_id instead."
  value       = null
}

output "ai_foundry_hub_name" {
  description = "DEPRECATED: AI Foundry Hub is no longer created. Use ai_foundry_project_name instead."
  value       = null
}

# Private Endpoint Outputs
output "ai_foundry_hub_private_endpoints" {
  description = "DEPRECATED: AI Foundry Hub is no longer created."
  value       = {}
}

output "ai_foundry_hub_workspace_url" {
  description = "DEPRECATED: AI Foundry Hub is no longer created. Use ai_foundry_project_url instead."
  value       = null
}

output "ai_foundry_project_id" {
  description = "The resource ID of the AI Foundry Project."
  value       = azapi_resource.ai_foundry_project.id
}

output "ai_foundry_project_name" {
  description = "The name of the AI Foundry Project."
  value       = azapi_resource.ai_foundry_project.name
}

output "ai_foundry_project_private_endpoints" {
  description = "A map of private endpoints created for the AI Foundry Project (via AI Services)."
  value = {
    for k, v in azurerm_private_endpoint.ai_foundry_project : k => {
      id           = v.id
      name         = v.name
      fqdn         = try(v.private_dns_zone_group[0].private_dns_zone_configs[0].record_sets[0].fqdn, null)
      ip_addresses = v.private_service_connection[0].private_ip_address
    }
  }
}

output "ai_foundry_project_workspace_url" {
  description = "The project URL of the AI Foundry Project."
  value       = try(azapi_resource.ai_foundry_project.output.properties.projectUrl, null)
}

# AI Search Outputs
output "ai_search" {
  description = "The AI Search service used for vector search and retrieval."
  value = var.existing_ai_search_resource_id != null ? {
    id                  = var.existing_ai_search_resource_id
    name                = data.azurerm_search_service.existing[0].name
    search_service_name = data.azurerm_search_service.existing[0].name
    } : {
    id                  = module.ai_search[0].resource_id
    name                = module.ai_search[0].resource.name
    search_service_name = module.ai_search[0].resource.name
  }
}

# AI Services Outputs
output "ai_services" {
  description = "The AI Services account with OpenAI and other AI models."
  value = {
    id          = azapi_resource.ai_services.id
    name        = azapi_resource.ai_services.name
    endpoint    = azapi_resource.ai_services.output.properties.endpoint
    deployments = var.ai_model_deployments
  }
}

# AI Services Endpoint and Keys (for examples)
output "ai_services_endpoint" {
  description = "The endpoint of the AI Services account."
  value       = azapi_resource.ai_services.output.properties.endpoint
}

output "ai_services_name" {
  description = "The name of the AI Services account."
  value       = azapi_resource.ai_services.name
}

# AI Services Private Endpoints
output "ai_services_private_endpoints" {
  description = "A map of private endpoints created for the AI Services account."
  value = {
    for k, v in azurerm_private_endpoint.ai_services : k => {
      id           = v.id
      name         = v.name
      fqdn         = try(v.private_dns_zone_group[0].private_dns_zone_configs[0].record_sets[0].fqdn, null)
      ip_addresses = v.private_service_connection[0].private_ip_address
    }
  }
}

output "azure_ai_project_name" {
  description = "Name of the deployed Azure AI Project."
  value       = azapi_resource.ai_foundry_project.name
}

output "azure_ai_search_name" {
  description = "Name of the deployed Azure AI Search service."
  value       = local.deploy_ai_search ? module.ai_search[0].resource.name : (var.existing_ai_search_resource_id != null ? split("/", var.existing_ai_search_resource_id)[8] : "")
}

output "azure_ai_services_name" {
  description = "Name of the deployed Azure AI Services account."
  value       = azapi_resource.ai_services.name
}

output "azure_container_registry_name" {
  description = "DEPRECATED: Container Registry has been moved to examples. Provide external container registry if needed."
  value       = ""
}

output "azure_key_vault_name" {
  description = "Name of the deployed Azure Key Vault."
  value       = local.deploy_key_vault ? module.key_vault[0].name : (var.existing_key_vault_resource_id != null ? data.azurerm_key_vault.existing[0].name : "")
}

output "azure_virtual_network_name" {
  description = "Name of the external Azure Virtual Network (provided by user via agent_subnet_resource_id)."
  value       = var.agent_subnet_resource_id != null ? split("/", var.agent_subnet_resource_id)[8] : ""
}

output "azure_virtual_network_subnet_name" {
  description = "Name of the external Azure Virtual Network Subnet (provided by user via agent_subnet_resource_id)."
  value       = var.agent_subnet_resource_id != null ? split("/", var.agent_subnet_resource_id)[10] : ""
}

# Legacy output for backward compatibility
output "cognitive_services" {
  description = "The AI Services account (legacy name for backward compatibility)."
  value = {
    id          = azapi_resource.ai_services.id
    name        = azapi_resource.ai_services.name
    endpoint    = azapi_resource.ai_services.output.properties.endpoint
    deployments = var.ai_model_deployments
  }
}

# Connection Information
output "connection_info" {
  description = "Connection information for integrating with the AI Foundry services."
  sensitive   = true
  value = {
    storage_account_connection = var.existing_storage_account_resource_id != null ? {
      account_name  = data.azurerm_storage_account.existing[0].name
      account_key   = data.azurerm_storage_account.existing[0].primary_access_key
      blob_endpoint = data.azurerm_storage_account.existing[0].primary_blob_endpoint
      dfs_endpoint  = data.azurerm_storage_account.existing[0].primary_dfs_endpoint
      } : {
      account_name  = module.storage_account[0].name
      account_key   = module.storage_account[0].resource.primary_access_key
      blob_endpoint = module.storage_account[0].resource.primary_blob_endpoint
      dfs_endpoint  = module.storage_account[0].resource.primary_dfs_endpoint
    }

    key_vault_connection = var.existing_key_vault_resource_id != null ? {
      vault_uri  = data.azurerm_key_vault.existing[0].vault_uri
      vault_name = data.azurerm_key_vault.existing[0].name
      } : {
      vault_uri  = module.key_vault[0].uri
      vault_name = module.key_vault[0].name
    }

    cosmos_db_connection = var.existing_cosmos_db_resource_id != null ? {
      endpoint     = data.azurerm_cosmosdb_account.existing[0].endpoint
      account_name = data.azurerm_cosmosdb_account.existing[0].name
      } : {
      endpoint     = "https://${module.cosmos_db[0].name}.documents.azure.com:443/"
      account_name = module.cosmos_db[0].name
    }

    ai_search_connection = var.existing_ai_search_resource_id != null ? {
      endpoint     = "https://${data.azurerm_search_service.existing[0].name}.search.windows.net"
      service_name = data.azurerm_search_service.existing[0].name
      } : {
      endpoint     = "https://${module.ai_search[0].resource.name}.search.windows.net"
      service_name = module.ai_search[0].resource.name
    }

    openai_connection = {
      endpoint     = azapi_resource.ai_services.output.properties.endpoint
      account_name = azapi_resource.ai_services.name
      deployments  = var.ai_model_deployments
    }
  }
}

# Cosmos DB Outputs
output "cosmos_db" {
  description = "The Cosmos DB account used for AI Foundry data storage."
  value = var.existing_cosmos_db_resource_id != null ? {
    id              = var.existing_cosmos_db_resource_id
    name            = data.azurerm_cosmosdb_account.existing[0].name
    endpoint        = data.azurerm_cosmosdb_account.existing[0].endpoint
    read_endpoints  = data.azurerm_cosmosdb_account.existing[0].read_endpoints
    write_endpoints = data.azurerm_cosmosdb_account.existing[0].write_endpoints
    } : {
    id              = module.cosmos_db[0].resource_id
    name            = module.cosmos_db[0].name
    endpoint        = "https://${module.cosmos_db[0].name}.documents.azure.com:443/"
    read_endpoints  = [] # This would need to be calculated based on geo-locations
    write_endpoints = [] # This would need to be calculated based on geo-locations
  }
}

# Key Vault Outputs
output "key_vault" {
  description = "The Key Vault used for secrets management."
  value = var.existing_key_vault_resource_id != null ? {
    id        = var.existing_key_vault_resource_id
    name      = data.azurerm_key_vault.existing[0].name
    vault_uri = data.azurerm_key_vault.existing[0].vault_uri
    } : {
    id        = module.key_vault[0].resource_id
    name      = module.key_vault[0].name
    vault_uri = module.key_vault[0].uri
  }
}

# Key Vault Outputs (for examples)
output "key_vault_id" {
  description = "The resource ID of the Key Vault."
  value       = var.existing_key_vault_resource_id != null ? var.existing_key_vault_resource_id : (local.deploy_key_vault ? module.key_vault[0].resource_id : null)
}

output "key_vault_name" {
  description = "The name of the Key Vault."
  value       = var.existing_key_vault_resource_id != null ? data.azurerm_key_vault.existing[0].name : (local.deploy_key_vault ? module.key_vault[0].name : null)
}

output "key_vault_uri" {
  description = "The URI of the Key Vault."
  value       = var.existing_key_vault_resource_id != null ? data.azurerm_key_vault.existing[0].vault_uri : (local.deploy_key_vault ? module.key_vault[0].uri : null)
}

# Managed Identity Outputs
output "managed_identities" {
  description = "Managed identities created for the AI Foundry services."
  value = {
    storage_account = var.existing_storage_account_resource_id == null ? try(module.storage_account[0].system_assigned_mi_principal_id, null) : null
    key_vault       = var.existing_key_vault_resource_id == null ? try(module.key_vault[0].system_assigned_mi_principal_id, null) : null
    cosmos_db       = var.existing_cosmos_db_resource_id == null ? try(module.cosmos_db[0].system_assigned_mi_principal_id, null) : null
    ai_search       = var.existing_ai_search_resource_id == null ? try(module.ai_search[0].system_assigned_mi_principal_id, null) : null
    ai_services     = try(azapi_resource.ai_services.identity[0].principal_id, null)
  }
}

# Private Endpoints Outputs
output "private_endpoints" {
  description = "All private endpoints created for the AI Foundry services."
  value = {
    storage_account = var.existing_storage_account_resource_id == null ? try(module.storage_account[0].private_endpoints, {}) : {}
    key_vault       = var.existing_key_vault_resource_id == null ? try(module.key_vault[0].private_endpoints, {}) : {}
    cosmos_db       = var.existing_cosmos_db_resource_id == null ? try(module.cosmos_db[0].private_endpoints, {}) : {}
    ai_search       = var.existing_ai_search_resource_id == null ? try(module.ai_search[0].private_endpoints, {}) : {}
    ai_services = {
      for k, v in azurerm_private_endpoint.ai_services : k => {
        id           = v.id
        name         = v.name
        fqdn         = try(v.private_dns_zone_group[0].private_dns_zone_configs[0].record_sets[0].fqdn, null)
        ip_addresses = v.private_service_connection[0].private_ip_address
      }
    }
  }
}

# Resource Group Outputs
output "resource_group" {
  description = "The resource group containing all AI Foundry resources."
  value = {
    id       = local.resource_group_id
    name     = local.resource_group_name
    location = local.location
  }
}

# Resource Group Outputs (for examples)
output "resource_group_id" {
  description = "The resource ID of the resource group."
  value       = local.resource_group_id
}

output "resource_group_name" {
  description = "Name of the deployed Azure Resource Group."
  value       = local.resource_group_name
}

# Required AVM Outputs
output "resource_id" {
  description = "The resource ID of the primary AI Foundry project resource."
  value       = azapi_resource.ai_foundry_project.id
}

# Storage Account Outputs
output "storage_account" {
  description = "The storage account used for AI Foundry workloads."
  value = var.existing_storage_account_resource_id != null ? {
    id                    = var.existing_storage_account_resource_id
    name                  = data.azurerm_storage_account.existing[0].name
    primary_blob_endpoint = data.azurerm_storage_account.existing[0].primary_blob_endpoint
    primary_dfs_endpoint  = data.azurerm_storage_account.existing[0].primary_dfs_endpoint
    } : {
    id                    = module.storage_account[0].resource_id
    name                  = module.storage_account[0].name
    primary_blob_endpoint = module.storage_account[0].resource.primary_blob_endpoint
    primary_dfs_endpoint  = module.storage_account[0].resource.primary_dfs_endpoint
  }
}

# Storage Account Outputs (for examples)
output "storage_account_id" {
  description = "The resource ID of the storage account."
  value       = var.existing_storage_account_resource_id != null ? var.existing_storage_account_resource_id : (local.deploy_storage_account ? module.storage_account[0].resource_id : null)
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = var.existing_storage_account_resource_id != null ? data.azurerm_storage_account.existing[0].name : (local.deploy_storage_account ? module.storage_account[0].name : null)
}

output "subnet_id" {
  description = "The resource ID of the agent subnet (external resource provided by user)."
  value       = var.agent_subnet_resource_id
}

# External Networking Resource References
output "virtual_network_id" {
  description = "The resource ID of the virtual network (external resource, derived from agent_subnet_resource_id)."
  value       = var.agent_subnet_resource_id != null ? join("/", slice(split("/", var.agent_subnet_resource_id), 0, 9)) : null
}
