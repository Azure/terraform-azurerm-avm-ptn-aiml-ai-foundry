data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  location = var.location
  name     = local.resource_group_name
  tags     = var.tags
}

resource "random_string" "resource_token" {
  length  = 5
  lower   = true
  numeric = true
  special = false
  upper   = false
}

module "dependent_resources" {
  source = "./modules/dependent-resources"

  ai_search_name                            = local.resource_names.ai_search
  cosmos_db_name                            = local.resource_names.cosmos_db
  deploy_ai_search                          = local.deploy_ai_search
  deploy_cosmos_db                          = local.deploy_cosmos_db
  deploy_key_vault                          = local.deploy_key_vault
  deploy_storage_account                    = local.deploy_storage_account
  key_vault_name                            = local.resource_names.key_vault
  location                                  = local.location
  resource_group_name                       = local.resource_group_name
  storage_account_name                      = local.resource_names.storage_account
  tenant_id                                 = data.azurerm_client_config.current.tenant_id
  private_dns_zone_resource_id_search       = var.private_dns_zone_resource_id_search
  private_dns_zone_resource_id_cosmosdb     = var.private_dns_zone_resource_id_cosmosdb
  private_dns_zone_resource_id_keyvault     = var.private_dns_zone_resource_id_keyvault
  private_dns_zone_resource_id_storage_blob = var.private_dns_zone_resource_id_storage_blob
  private_endpoint_subnet_id                = var.private_endpoint_subnet_id
  tags                                      = var.tags
}

module "ai_foundry" {
  source = "./modules/ai-foundry"

  ai_foundry_name                         = local.resource_names.ai_foundry
  location                                = local.location
  resource_group_id                       = local.resource_group_id
  resource_group_name                     = local.resource_group_name
  private_endpoint_subnet_id              = var.private_endpoint_subnet_id
  private_dns_zone_resource_id_ai_foundry = var.private_dns_zone_resource_id_ai_foundry
  ai_model_deployments                    = var.ai_model_deployments
  tags                                    = var.tags

  depends_on = [
    azurerm_resource_group.this
  ]
}

module "ai_foundry_project" {
  source = "./modules/ai-foundry-project"

  ai_agent_host_name              = local.resource_names.ai_agent_host
  ai_foundry_id                   = module.ai_foundry.ai_foundry_id
  ai_foundry_project_description  = var.ai_foundry_project_description
  ai_foundry_project_display_name = local.resource_names.ai_foundry_project_display_name
  ai_foundry_project_name         = local.resource_names.ai_foundry_project
  ai_search_id                    = try(module.dependent_resources.ai_search_id, null)
  ai_search_name                  = local.resource_names.ai_search
  cosmos_db_id                    = try(module.dependent_resources.cosmos_db_id, null)
  cosmos_db_name                  = local.resource_names.cosmos_db
  deploy_ai_search                = local.deploy_ai_search
  deploy_cosmos_db                = local.deploy_cosmos_db
  deploy_storage_account          = local.deploy_storage_account
  location                        = local.location
  storage_account_id              = try(module.dependent_resources.storage_account_id, null)
  storage_account_name            = local.resource_names.storage_account
  create_ai_agent_service         = var.create_ai_agent_service
  tags                            = var.tags

  depends_on = [
    module.ai_foundry,
    module.dependent_resources
  ]
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = local.resource_group_id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = local.resource_group_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
