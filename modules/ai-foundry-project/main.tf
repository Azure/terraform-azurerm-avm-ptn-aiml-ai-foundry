resource "azapi_resource" "ai_foundry_project" {
  location  = var.location
  name      = var.ai_foundry_project_name
  parent_id = var.ai_foundry_id
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
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

locals {
  # Extract project internal ID and format as GUID for container naming
  project_id_guid = var.create_ai_agent_service ? "${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 0, 8)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 8, 4)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 12, 4)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 16, 4)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 20, 12)}" : ""
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
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
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
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
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
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
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
  type      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-06-01"
  body = {
    properties = {
      capabilityHostKind = "Agents"
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

# Role assignments are handled in the main module to avoid dependency issues

# Data Plane Role Assignments for Cosmos DB containers created by AI Foundry Project
resource "azurerm_cosmosdb_sql_role_assignment" "thread_message_store" {
  count = var.create_ai_agent_service && var.create_project_connections ? 1 : 0

  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${azapi_resource.ai_foundry_project.output.identity.principalId}userthreadmessage_dbsqlrole")
  resource_group_name = split("/", var.cosmos_db_id)[4]
  account_name        = basename(var.cosmos_db_id)
  scope               = "${var.cosmos_db_id}/dbs/enterprise_memory/colls/${local.project_id_guid}-thread-message-store"
  role_definition_id  = "${var.cosmos_db_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azapi_resource.ai_foundry_project.output.identity.principalId

  depends_on = [
    azapi_resource.ai_agent_capability_host,
    time_sleep.wait_project_identities
  ]
}

resource "azurerm_cosmosdb_sql_role_assignment" "system_thread_message_store" {
  count = var.create_ai_agent_service && var.create_project_connections ? 1 : 0

  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${azapi_resource.ai_foundry_project.output.identity.principalId}systemthread_dbsqlrole")
  resource_group_name = split("/", var.cosmos_db_id)[4]
  account_name        = basename(var.cosmos_db_id)
  scope               = "${var.cosmos_db_id}/dbs/enterprise_memory/colls/${local.project_id_guid}-system-thread-message-store"
  role_definition_id  = "${var.cosmos_db_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azapi_resource.ai_foundry_project.output.identity.principalId

  depends_on = [
    azurerm_cosmosdb_sql_role_assignment.thread_message_store
  ]
}

resource "azurerm_cosmosdb_sql_role_assignment" "agent_entity_store" {
  count = var.create_ai_agent_service && var.create_project_connections ? 1 : 0

  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${azapi_resource.ai_foundry_project.output.identity.principalId}entitystore_dbsqlrole")
  resource_group_name = split("/", var.cosmos_db_id)[4]
  account_name        = basename(var.cosmos_db_id)
  scope               = "${var.cosmos_db_id}/dbs/enterprise_memory/colls/${local.project_id_guid}-agent-entity-store"
  role_definition_id  = "${var.cosmos_db_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azapi_resource.ai_foundry_project.output.identity.principalId

  depends_on = [
    azurerm_cosmosdb_sql_role_assignment.system_thread_message_store
  ]
}

# Advanced Storage Blob Data Owner assignment with ABAC conditions
resource "azurerm_role_assignment" "storage_blob_data_owner" {
  count = var.create_ai_agent_service && var.create_project_connections ? 1 : 0

  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${azapi_resource.ai_foundry_project.output.identity.principalId}${basename(var.storage_account_id)}storageblobdataowner")
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azapi_resource.ai_foundry_project.output.identity.principalId
  condition_version    = "2.0"
  condition            = <<-EOT
  (
    (
      !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/read'})
      AND  !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/filter/action'})
      AND  !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/write'})
    )
    OR
    (@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringStartsWithIgnoreCase '${local.project_id_guid}'
    AND @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringLikeIgnoreCase '*-azureml-agent')
  )
  EOT

  depends_on = [
    azapi_resource.ai_agent_capability_host,
    time_sleep.wait_project_identities
  ]
}
