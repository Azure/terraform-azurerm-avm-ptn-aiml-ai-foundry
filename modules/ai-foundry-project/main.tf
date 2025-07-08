resource "azapi_resource" "ai_foundry_project" {
  location  = var.location
  name      = var.ai_foundry_project_name
  parent_id = var.ai_foundry_id
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  body = {
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      displayName = var.ai_foundry_project_display_name
      description = var.ai_foundry_project_description
    }
  }
  response_export_values = [
    "identity.principalId",
    "properties.internalId"
  ]
  schema_validation_enabled = false
  tags                      = var.tags
}

resource "time_sleep" "wait_project_identities" {
  create_duration = "10s"

  depends_on = [
    azapi_resource.ai_foundry_project
  ]
}

resource "azapi_resource" "ai_foundry_project_connection_storage" {
  count = var.create_project_connections ? 1 : 0

  name      = basename(var.storage_account_id)
  parent_id = azapi_resource.ai_foundry_project.id
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  body = {
    properties = {
      category = "AzureStorageAccount"
      target   = "https://${basename(var.storage_account_id)}.blob.core.windows.net/"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.storage_account_id
        location   = var.location
      }
    }
  }
  response_export_values = [
    "identity.principalId"
  ]
  schema_validation_enabled = false

  depends_on = [azapi_resource.ai_foundry_project]
}

resource "azapi_resource" "ai_foundry_project_connection_cosmos" {
  count = var.create_project_connections ? 1 : 0

  name      = basename(var.cosmos_db_id)
  parent_id = azapi_resource.ai_foundry_project.id
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  body = {
    properties = {
      category = "CosmosDb"
      target   = "https://${basename(var.cosmos_db_id)}.documents.azure.com:443/"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.cosmos_db_id
        location   = var.location
      }
    }
  }
  response_export_values = [
    "identity.principalId"
  ]
  schema_validation_enabled = false

  depends_on = [azapi_resource.ai_foundry_project]
}

resource "azapi_resource" "ai_foundry_project_connection_search" {
  count = var.create_project_connections ? 1 : 0

  name      = basename(var.ai_search_id)
  parent_id = azapi_resource.ai_foundry_project.id
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  body = {
    properties = {
      category = "CognitiveSearch"
      target   = "https://${basename(var.ai_search_id)}.search.windows.net"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2024-05-01-preview"
        ResourceId = var.ai_search_id
        location   = var.location
      }
    }
  }
  schema_validation_enabled = false

  depends_on = [azapi_resource.ai_foundry_project]
}

resource "azapi_resource" "ai_agent_capability_host" {
  count = var.create_ai_agent_service ? 1 : 0

  name      = var.ai_agent_host_name
  parent_id = azapi_resource.ai_foundry_project.id
  type      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  body = {
    properties = {
      capabilityHostKind = "Agents"
      description        = "AI Agent capability host for ${var.ai_foundry_project_name}"
      vectorStoreConnections = var.create_project_connections && var.ai_search_id != null ? [
        azapi_resource.ai_foundry_project_connection_search[0].name
      ] : []
      storageConnections = var.create_project_connections && var.storage_account_id != null ? [
        azapi_resource.ai_foundry_project_connection_storage[0].name
      ] : []
      threadStorageConnections = var.create_project_connections && var.cosmos_db_id != null ? [
        azapi_resource.ai_foundry_project_connection_cosmos[0].name
      ] : []
    }
  }
  schema_validation_enabled = false

  depends_on = [
    azapi_resource.ai_foundry_project,
    azapi_resource.ai_foundry_project_connection_storage,
    azapi_resource.ai_foundry_project_connection_cosmos,
    azapi_resource.ai_foundry_project_connection_search
  ]
}
