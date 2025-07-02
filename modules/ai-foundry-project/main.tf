resource "azapi_resource" "ai_foundry_project" {
  location                  = var.location
  name                      = var.ai_foundry_project_name
  parent_id                 = var.ai_foundry_id
  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  schema_validation_enabled = false
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
  tags = var.tags
}

resource "time_sleep" "wait_project_identities" {
  depends_on = [
    azapi_resource.ai_foundry_project
  ]
  create_duration = "10s"
}

resource "azapi_resource" "ai_foundry_project_connection_storage" {
  count = var.deploy_storage_account ? 1 : 0

  name                      = var.storage_account_name
  parent_id                 = azapi_resource.ai_foundry_project.id
  schema_validation_enabled = false
  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
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

  response_export_values = [
    "identity.principalId"
  ]

  depends_on = [azapi_resource.ai_foundry_project]
}

resource "azapi_resource" "ai_foundry_project_connection_cosmos" {
  count = var.deploy_cosmos_db ? 1 : 0

  name                      = var.cosmos_db_name
  parent_id                 = azapi_resource.ai_foundry_project.id
  schema_validation_enabled = false
  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  body = {
    properties = {
      category = "CosmosDb"
      target   = "https://${var.cosmos_db_name}.documents.azure.com:443/"
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

  depends_on = [azapi_resource.ai_foundry_project]
}

resource "azapi_resource" "ai_foundry_project_connection_search" {
  count = var.deploy_ai_search ? 1 : 0

  name                      = var.ai_search_name
  parent_id                 = azapi_resource.ai_foundry_project.id
  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  schema_validation_enabled = false
  body = {
    properties = {
      category = "CognitiveSearch"
      target   = "https://${var.ai_search_name}.search.windows.net"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2024-05-01-preview"
        ResourceId = var.ai_search_id
        location   = var.location
      }
    }
  }

  depends_on = [azapi_resource.ai_foundry_project]
}

resource "azapi_resource" "ai_agent_capability_host" {
  count = var.create_ai_agent_service ? 1 : 0

  name                      = var.ai_agent_host_name
  parent_id                 = azapi_resource.ai_foundry_project.id
  schema_validation_enabled = false
  type                      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  body = {
    properties = {
      capabilityHostKind = "Agents"
      description        = "AI Agent capability host for ${var.ai_foundry_project_name}"
      vectorStoreConnections = [
        var.vector_store_connections
      ]
      storageConnections = [
        var.storage_connections
      ]
      threadStorageConnections = [
        var.thread_storage_connections
      ]
    }
  }

  depends_on = [
    azapi_resource.ai_foundry_project,
    azapi_resource.ai_foundry_project_connection_storage,
    azapi_resource.ai_foundry_project_connection_cosmos,
    azapi_resource.ai_foundry_project_connection_search
  ]
}
