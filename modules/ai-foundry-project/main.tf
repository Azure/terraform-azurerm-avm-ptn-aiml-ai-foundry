resource "azapi_resource" "ai_foundry_project" {
  count = var.create_ai_foundry_project ? 1 : 0

  location  = var.location
  name      = var.ai_foundry_project_name
  parent_id = var.ai_foundry_id
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  body = {
    properties = {
      displayName = var.ai_foundry_project_display_name
      description = var.ai_foundry_project_description
    }
  }
  tags = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azapi_resource" "ai_foundry_project_connection_storage" {
  count = var.create_ai_foundry_project && var.deploy_storage_account ? 1 : 0

  name      = var.storage_account_name
  parent_id = azapi_resource.ai_foundry_project[0].id
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  body = {
    properties = {
      category = "AzureStorageAccount"
      target   = "https://${var.storage_account_name}.blob.core.windows.net/"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.storage_account_id
        location   = var.location
      }
    }
  }

  depends_on = [azapi_resource.ai_foundry_project]
}

resource "azapi_resource" "ai_foundry_project_connection_cosmos" {
  count = var.create_ai_foundry_project && var.deploy_cosmos_db ? 1 : 0

  name      = var.cosmos_db_name
  parent_id = azapi_resource.ai_foundry_project[0].id
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  body = {
    properties = {
      category = "CosmosDB"
      target   = "https://${var.cosmos_db_name}.documents.azure.com:443/"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.cosmos_db_id
        location   = var.location
      }
    }
  }

  depends_on = [azapi_resource.ai_foundry_project]
}

resource "azapi_resource" "ai_foundry_project_connection_search" {
  count = var.create_ai_foundry_project && var.deploy_ai_search ? 1 : 0

  name      = var.ai_search_name
  parent_id = azapi_resource.ai_foundry_project[0].id
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  body = {
    properties = {
      category = "CognitiveSearch"
      target   = "https://${var.ai_search_name}.search.windows.net"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.ai_search_id
        location   = var.location
      }
    }
  }

  depends_on = [azapi_resource.ai_foundry_project]
}

resource "azapi_resource" "ai_agent_capability_host" {
  count = var.create_ai_agent_service ? 1 : 0

  name      = var.ai_agent_host_name
  parent_id = azapi_resource.ai_foundry_project[0].id
  type      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  body = {
    properties = {
      capabilityHostKind = "Agents"
      description        = "AI Agent capability host for ${var.ai_foundry_project_name}"
      # storageConnections       = var.storage_connections
      # aiServicesConnections    = [var.ai_services_id]
      # threadStorageConnections = var.thread_storage_connections
      # vectorStoreConnections   = var.vector_store_connections
      # customerSubnet           = var.agent_subnet_resource_id
    }
  }

  depends_on = [
    azapi_resource.ai_foundry_project,
    azapi_resource.ai_foundry_project_connection_storage,
    azapi_resource.ai_foundry_project_connection_cosmos,
    azapi_resource.ai_foundry_project_connection_search
  ]
}
