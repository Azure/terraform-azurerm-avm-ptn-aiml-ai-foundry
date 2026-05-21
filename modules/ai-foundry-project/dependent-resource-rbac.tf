locals {
  ai_search_default_role_assignments = {
    search_index_data_contributor = {
      name                       = "${var.name}-search-index-data-contributor"
      role_definition_id_or_name = "Search Index Data Contributor"
    }
    search_service_contributor = {
      name                       = "${var.name}-search-service-contributor"
      role_definition_id_or_name = "Search Service Contributor"
    }
  }
  cosmosdb_default_role_assignments = {
    cosmosdb_operator = {
      name                       = "${var.name}-cosmosdb-operator"
      role_definition_id_or_name = "Cosmos DB Operator"
    }
  }
  storage_account_default_role_assignments = {
    storage_blob_data_contributor = {
      name                       = "${var.name}-storage-blob-data-contributor"
      role_definition_id_or_name = "Storage Blob Data Contributor"
    }
  }

  # Principals that need Cosmos DB / Storage data-plane access for the Standard Agent setup.
  # Always includes the project's system-assigned identity. When the parent Foundry account also
  # has user-assigned managed identities, those principals must also be granted the same roles
  # (per the Standard Agent Setup documentation).
  cosmos_data_plane_principal_ids = compact(concat(
    [azapi_resource.ai_foundry_project.output.identity.principalId],
    var.account_user_assigned_identity_principal_ids
  ))
}

resource "azurerm_role_assignment" "ai_search_role_assignments" {
  for_each = var.create_project_connections ? local.ai_search_default_role_assignments : {}

  principal_id   = azapi_resource.ai_foundry_project.output.identity.principalId
  scope          = var.create_project_connections ? var.ai_search_id : "/n/o/t/u/s/e/d"
  principal_type = "ServicePrincipal"
  #name                 = each.key
  role_definition_name = each.value.role_definition_id_or_name

  depends_on = [time_sleep.wait_project_identities]
}

resource "azurerm_role_assignment" "cosmosdb_role_assignments" {
  for_each = var.create_project_connections ? local.cosmosdb_default_role_assignments : {}

  principal_id   = azapi_resource.ai_foundry_project.output.identity.principalId
  scope          = var.create_project_connections ? var.cosmos_db_id : "/n/o/t/u/s/e/d"
  principal_type = "ServicePrincipal"
  #name                 = each.key
  role_definition_name = each.value.role_definition_id_or_name

  depends_on = [time_sleep.wait_project_identities]
}


resource "azurerm_role_assignment" "storage_role_assignments" {
  for_each = var.create_project_connections ? local.storage_account_default_role_assignments : {}

  principal_id   = azapi_resource.ai_foundry_project.output.identity.principalId
  scope          = var.create_project_connections ? var.storage_account_id : "/n/o/t/u/s/e/d"
  principal_type = "ServicePrincipal"
  #name                 = each.key
  role_definition_name = each.value.role_definition_id_or_name

  depends_on = [time_sleep.wait_project_identities]
}


# Control-plane role assignments are handled in the main module to avoid dependency issues - causes cycle errors if done externally.  Move here.
# Data Plane Role Assignment for Cosmos DB - scoped at database level so it covers all containers,
# including the `<project-guid>-agent-definitions-v1` container that is created dynamically by AI
# Foundry at first agent deployment. Container-level scoping was insufficient (issue #72).
resource "azurerm_cosmosdb_sql_role_assignment" "enterprise_memory_db_contributor" {
  for_each = var.create_ai_agent_service && var.create_project_connections ? toset(local.cosmos_data_plane_principal_ids) : toset([])

  account_name        = basename(var.cosmos_db_id)
  principal_id        = each.value
  resource_group_name = split("/", var.cosmos_db_id)[4]
  role_definition_id  = "${var.cosmos_db_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  scope               = "${var.cosmos_db_id}/dbs/enterprise_memory"
  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${each.value}enterprisememory_dbsqlrole")

  depends_on = [
    azapi_resource.ai_agent_capability_host
  ]
}

# Advanced Storage Blob Data Owner assignment with ABAC conditions. Applied to every principal
# that needs data-plane access (project SMI plus any account-level UMI principals).
resource "azurerm_role_assignment" "storage_blob_data_owner" {
  for_each = var.create_ai_agent_service && var.create_project_connections ? toset(local.cosmos_data_plane_principal_ids) : toset([])

  principal_id         = each.value
  scope                = var.storage_account_id
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
  condition_version    = "2.0"
  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${each.value}${basename(var.storage_account_id)}storageblobdataowner")
  principal_type       = "ServicePrincipal"
  role_definition_name = "Storage Blob Data Owner"

  depends_on = [
    azapi_resource.ai_agent_capability_host
  ]
}
