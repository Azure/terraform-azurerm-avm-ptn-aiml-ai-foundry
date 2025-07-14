data "azurerm_client_config" "current" {}

resource "random_string" "resource_token" {
  length  = 5
  lower   = true
  numeric = true
  special = false
  upper   = false
}

module "ai_foundry" {
  source = "./modules/ai-foundry"

  ai_foundry_name                         = local.resource_names.ai_foundry
  location                                = local.location
  resource_group_resource_id              = var.resource_group_resource_id
  agent_subnet_resource_id                = var.agent_subnet_resource_id
  ai_model_deployments                    = var.ai_model_deployments
  create_ai_agent_service                 = var.create_ai_agent_service
  create_private_endpoints                = var.create_private_endpoints
  private_dns_zone_resource_id_ai_foundry = var.private_dns_zone_resource_id_ai_foundry
  private_endpoint_subnet_resource_id     = var.private_endpoint_subnet_resource_id
  tags                                    = var.tags
}

module "ai_foundry_project" {
  source = "./modules/ai-foundry-project"

  ai_agent_host_name              = local.resource_names.ai_agent_host
  ai_foundry_id                   = module.ai_foundry.ai_foundry_id
  ai_foundry_project_description  = var.ai_foundry_project_description
  ai_foundry_project_display_name = local.resource_names.ai_foundry_project_display_name
  ai_foundry_project_name         = local.resource_names.ai_foundry_project
  location                        = local.location
  ai_search_id                    = try(var.ai_search_definition.existing_resource_id, null) != null ? var.ai_search_definition.existing_resource_id : module.ai_search[0].resource_id
  cosmos_db_id                    = try(var.cosmosdb_definition.existing_resource_id, null) != null ? var.cosmosdb_definition.existing_resource_id : module.cosmosdb[0].resource_id
  create_ai_agent_service         = var.create_ai_agent_service
  create_project_connections      = var.create_project_connections
  storage_account_id              = try(var.storage_account_definition.existing_resource_id, null) != null ? var.storage_account_definition.existing_resource_id : module.storage_account[0].resource_id
  tags                            = var.tags

  depends_on = [
    module.ai_foundry
  ]
}

# Control Plane Role Assignments for AI Foundry Project System Identity
# Only created when project connections are enabled and dependent resources exist
#TODO: Add RBAC TO the cosmos interface definition and merge the RBAC configuration there.
#configure RBAC on existing resources if supplied. Requires sufficient permissions to assign roles on those resources.
resource "azurerm_role_assignment" "cosmosdb_existing" {
  for_each = var.cosmosdb_definition.existing_resource_id != null ? local.cosmosdb_role_assignments : {}

  principal_id                           = module.ai_foundry_project.ai_foundry_project_system_identity_principal_id
  scope                                  = var.cosmosdb_definition.existing_resource_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azurerm_role_assignment" "search_existing" {
  for_each = var.ai_search_definition.existing_resource_id != null ? local.ai_search_role_assignments : {}

  principal_id                           = module.ai_foundry_project.ai_foundry_project_system_identity_principal_id
  scope                                  = var.ai_search_definition.existing_resource_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azurerm_role_assignment" "storage_existing" {
  for_each = var.storage_account_definition.existing_resource_id != null ? local.storage_account_role_assignments : {}

  principal_id                           = module.ai_foundry_project.ai_foundry_project_system_identity_principal_id
  scope                                  = var.storage_account_definition.existing_resource_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azurerm_role_assignment" "key_vault_existing" {
  for_each = var.key_vault_definition.existing_resource_id != null ? local.key_vault_role_assignments : {}

  principal_id                           = module.ai_foundry_project.ai_foundry_project_system_identity_principal_id
  scope                                  = var.key_vault_definition.existing_resource_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

#TODO: Remove this? Lock should apply to the foundry resource not the resource group?
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = var.resource_group_resource_id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

#TODO: Remove this? RBAC should apply to the foundry resource not the resource group?
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = var.resource_group_resource_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
