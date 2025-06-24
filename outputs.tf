# ========================================
# Resource Group Outputs
# ========================================
output "resource_group" {
  description = "The resource group containing all AI Foundry resources."
  value = {
    id       = azurerm_resource_group.this.id
    name     = azurerm_resource_group.this.name
    location = azurerm_resource_group.this.location
  }
}

# ========================================
# Storage Account Outputs
# ========================================
output "storage_account" {
  description = "The storage account used for AI Foundry workloads."
  value = var.existing_storage_account_resource_id != null ? {
    id                  = var.existing_storage_account_resource_id
    name               = data.azurerm_storage_account.existing[0].name
    primary_blob_endpoint = data.azurerm_storage_account.existing[0].primary_blob_endpoint
    primary_dfs_endpoint  = data.azurerm_storage_account.existing[0].primary_dfs_endpoint
  } : {
    id                  = module.storage_account[0].resource_id
    name               = module.storage_account[0].name
    primary_blob_endpoint = module.storage_account[0].primary_blob_endpoint
    primary_dfs_endpoint  = module.storage_account[0].primary_dfs_endpoint
  }
}

# ========================================
# Key Vault Outputs
# ========================================
output "key_vault" {
  description = "The Key Vault used for AI Foundry secrets management."
  value = var.existing_key_vault_resource_id != null ? {
    id         = var.existing_key_vault_resource_id
    name       = data.azurerm_key_vault.existing[0].name
    vault_uri  = data.azurerm_key_vault.existing[0].vault_uri
  } : {
    id         = module.key_vault[0].resource_id
    name       = module.key_vault[0].name
    vault_uri  = module.key_vault[0].vault_uri
  }
}

# ========================================
# Cosmos DB Outputs
# ========================================
output "cosmos_db" {
  description = "The Cosmos DB account used for AI Foundry data storage."
  value = var.existing_cosmos_db_resource_id != null ? {
    id                     = var.existing_cosmos_db_resource_id
    name                   = data.azurerm_cosmosdb_account.existing[0].name
    endpoint              = data.azurerm_cosmosdb_account.existing[0].endpoint
    read_endpoints        = data.azurerm_cosmosdb_account.existing[0].read_endpoints
    write_endpoints       = data.azurerm_cosmosdb_account.existing[0].write_endpoints
  } : {
    id                     = module.cosmos_db[0].resource_id
    name                   = module.cosmos_db[0].name
    endpoint              = module.cosmos_db[0].endpoint
    read_endpoints        = module.cosmos_db[0].read_endpoints
    write_endpoints       = module.cosmos_db[0].write_endpoints
  }
}

# ========================================
# AI Search Outputs
# ========================================
output "ai_search" {
  description = "The AI Search service used for vector search and retrieval."
  value = var.existing_ai_search_resource_id != null ? {
    id                = var.existing_ai_search_resource_id
    name              = data.azurerm_search_service.existing[0].name
    search_service_name = data.azurerm_search_service.existing[0].name
  } : {
    id                = module.ai_search[0].resource_id
    name              = module.ai_search[0].name
    search_service_name = module.ai_search[0].name
  }
}

# ========================================
# Cognitive Services / OpenAI Outputs
# ========================================
output "cognitive_services" {
  description = "The Cognitive Services account with OpenAI models."
  value = {
    id                = module.cognitive_services.resource_id
    name              = module.cognitive_services.name
    endpoint          = module.cognitive_services.endpoint
    deployments       = var.openai_deployments
  }
}

# ========================================
# Private Endpoints Outputs
# ========================================
output "private_endpoints" {
  description = "All private endpoints created for the AI Foundry services."
  value = {
    storage_account     = var.existing_storage_account_resource_id == null ? try(module.storage_account[0].private_endpoints, {}) : {}
    key_vault          = var.existing_key_vault_resource_id == null ? try(module.key_vault[0].private_endpoints, {}) : {}
    cosmos_db          = var.existing_cosmos_db_resource_id == null ? try(module.cosmos_db[0].private_endpoints, {}) : {}
    ai_search          = var.existing_ai_search_resource_id == null ? try(module.ai_search[0].private_endpoints, {}) : {}
    cognitive_services = try(module.cognitive_services.private_endpoints, {})
  }
}

# ========================================
# Connection Information
# ========================================
output "connection_info" {
  description = "Connection information for integrating with the AI Foundry services."
  value = {
    storage_account_connection = var.existing_storage_account_resource_id != null ? {
      account_name = data.azurerm_storage_account.existing[0].name
      account_key  = data.azurerm_storage_account.existing[0].primary_access_key
      blob_endpoint = data.azurerm_storage_account.existing[0].primary_blob_endpoint
      dfs_endpoint  = data.azurerm_storage_account.existing[0].primary_dfs_endpoint
    } : {
      account_name = module.storage_account[0].name
      account_key  = module.storage_account[0].primary_access_key
      blob_endpoint = module.storage_account[0].primary_blob_endpoint
      dfs_endpoint  = module.storage_account[0].primary_dfs_endpoint
    }

    key_vault_connection = var.existing_key_vault_resource_id != null ? {
      vault_uri = data.azurerm_key_vault.existing[0].vault_uri
      vault_name = data.azurerm_key_vault.existing[0].name
    } : {
      vault_uri = module.key_vault[0].vault_uri
      vault_name = module.key_vault[0].name
    }

    cosmos_db_connection = var.existing_cosmos_db_resource_id != null ? {
      endpoint = data.azurerm_cosmosdb_account.existing[0].endpoint
      account_name = data.azurerm_cosmosdb_account.existing[0].name
    } : {
      endpoint = module.cosmos_db[0].endpoint
      account_name = module.cosmos_db[0].name
    }

    ai_search_connection = var.existing_ai_search_resource_id != null ? {
      endpoint = "https://${data.azurerm_search_service.existing[0].name}.search.windows.net"
      service_name = data.azurerm_search_service.existing[0].name
    } : {
      endpoint = "https://${module.ai_search[0].name}.search.windows.net"
      service_name = module.ai_search[0].name
    }

    openai_connection = {
      endpoint = module.cognitive_services.endpoint
      account_name = module.cognitive_services.name
      deployments = var.openai_deployments
    }
  }
  sensitive = true
}

# ========================================
# Managed Identity Outputs
# ========================================
output "managed_identities" {
  description = "Managed identities created for the AI Foundry services."
  value = {
    storage_account = var.existing_storage_account_resource_id == null ? try(module.storage_account[0].system_assigned_mi_principal_id, null) : null
    cognitive_services = try(module.cognitive_services.system_assigned_mi_principal_id, null)
  }
}
