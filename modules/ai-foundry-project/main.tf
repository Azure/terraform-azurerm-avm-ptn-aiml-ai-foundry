data "azapi_resource" "project_user_assigned_identity" {
  for_each = var.managed_identities.user_assigned_resource_ids

  resource_id            = each.value
  type                   = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  response_export_values = ["properties.principalId"]
}

resource "azapi_resource" "ai_foundry_project" {
  location  = var.location
  name      = var.name
  parent_id = var.ai_foundry_id
  type      = var.resource_types.cognitiveservices_accounts_projects
  body = {
    sku = {
      name = var.sku
    }
    identity = {
      type                   = local.project_identity_type
      userAssignedIdentities = length(var.managed_identities.user_assigned_resource_ids) > 0 ? local.project_user_assigned_identities : null
    }
    properties = {
      displayName = var.display_name
      description = var.description
    }
  }
  # The CognitiveServices project delete is an async operation whose server-side
  # cascade can race with a concurrent etag change, surfacing a 412
  # IfMatchPreconditionFailed even though azapi sends a wildcard If-Match. The
  # wildcard header plus a retry on that error makes terraform destroy resilient
  # to the race.
  delete_headers = { "If-Match" = "*" }
  response_export_values = [
    "identity.principalId",
    "identity.userAssignedIdentities",
    "properties.internalId"
  ]
  retry                     = var.retry
  schema_validation_enabled = false
  tags                      = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "time_sleep" "wait_project_identities" {
  create_duration = "10s"

  depends_on = [azapi_resource.ai_foundry_project]
}

resource "azapi_resource" "connection_storage" {
  count = var.create_project_connections ? 1 : 0

  name      = basename(var.create_project_connections ? "${var.name}-${substr(md5(lower(basename(var.storage_account_id))), 0, 6)}" : "/n/o/t/u/s/e/d")
  parent_id = azapi_resource.ai_foundry_project.id
  type      = var.resource_types.cognitiveservices_accounts_projects_connections
  body = {
    properties = {
      category = "AzureStorageAccount"
      target   = "https://${basename(var.create_project_connections ? var.storage_account_id : "/n/o/t/u/s/e/d")}.blob.core.windows.net/"
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
  retry                     = var.retry
  schema_validation_enabled = false

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [azapi_resource.connection_cosmos, azurerm_role_assignment.storage_role_assignments]
}

resource "azapi_resource" "connection_cosmos" {
  count = var.create_project_connections ? 1 : 0

  name      = basename(var.create_project_connections ? "${var.name}-${substr(md5(lower(basename(var.cosmos_db_id))), 0, 6)}" : "/n/o/t/u/s/e/d")
  parent_id = azapi_resource.ai_foundry_project.id
  type      = var.resource_types.cognitiveservices_accounts_projects_connections
  body = {
    properties = {
      category = "CosmosDb"
      target   = "https://${basename(var.create_project_connections ? var.cosmos_db_id : "/n/o/t/u/s/e/d")}.documents.azure.com:443/"
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
  retry                     = var.retry
  schema_validation_enabled = false

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [azurerm_role_assignment.cosmosdb_role_assignments]
}

resource "azapi_resource" "connection_search" {
  count = var.create_project_connections ? 1 : 0

  name      = basename(var.create_project_connections ? "${var.name}-${substr(md5(lower(basename(var.ai_search_id))), 0, 6)}" : "/n/o/t/u/s/e/d")
  parent_id = azapi_resource.ai_foundry_project.id
  type      = var.resource_types.cognitiveservices_accounts_projects_connections
  body = {
    properties = {
      category = "CognitiveSearch"
      target   = "https://${basename(var.create_project_connections ? var.ai_search_id : "/n/o/t/u/s/e/d")}.search.windows.net"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2024-05-01-preview"
        ResourceId = var.ai_search_id
        location   = var.location
      }
    }
  }
  retry                     = var.retry
  schema_validation_enabled = false

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    ignore_changes = [name]
  }
  depends_on = [azurerm_role_assignment.ai_search_role_assignments,
    azapi_resource.connection_cosmos,
  azapi_resource.connection_storage]
}

#TODO: do we need to add support for Key Vault connections?
resource "azapi_resource" "ai_agent_capability_host" {
  count = var.create_ai_agent_service && var.create_project_connections ? 1 : 0

  name      = var.ai_agent_host_name
  parent_id = azapi_resource.ai_foundry_project.id
  type      = var.resource_types.cognitiveservices_accounts_projects_capability_hosts
  body = {
    properties = {
      capabilityHostKind = "Agents"
      vectorStoreConnections = var.ai_search_id != null ? [
        azapi_resource.connection_search[0].name
      ] : []
      storageConnections = var.storage_account_id != null ? [
        azapi_resource.connection_storage[0].name
      ] : []
      threadStorageConnections = var.cosmos_db_id != null ? [
        azapi_resource.connection_cosmos[0].name
      ] : []
    }
  }
  retry                     = var.retry
  schema_validation_enabled = false

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    azapi_resource.connection_storage,
    azapi_resource.connection_cosmos,
    azapi_resource.connection_search,
    time_sleep.wait_rbac_before_capability_host,
    var.account_capability_host_id
  ]
}

resource "time_sleep" "wait_rbac_before_capability_host" {
  create_duration = "60s"

  depends_on = [
    azapi_resource.ai_foundry_project,
    azapi_resource.connection_storage,
    azapi_resource.connection_cosmos,
    azapi_resource.connection_search,
    azurerm_role_assignment.ai_search_role_assignments,
    azurerm_role_assignment.cosmosdb_role_assignments,
    azurerm_role_assignment.storage_role_assignments,
    time_sleep.wait_project_identities
  ]
}
