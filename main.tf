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

module "ai_foundry" {
  source = "./modules/ai-foundry"

  ai_foundry_name         = local.resource_names.ai_foundry
  location                = local.location
  resource_group_id       = local.resource_group_id
  resource_group_name     = local.resource_group_name
  agent_subnet_id         = var.agent_subnet_id
  ai_model_deployments    = var.ai_model_deployments
  create_ai_agent_service = var.create_ai_agent_service
  customer_managed_key    = var.customer_managed_key
  private_endpoints       = var.private_endpoints
  private_endpoints_manage_dns_zone_group = var.private_endpoints_manage_dns_zone_group
  tags                    = var.tags

  # AI Foundry API parameters
  kind                                       = var.ai_foundry_kind
  sku_name                                   = var.ai_foundry_sku_name
  identity_type                              = var.ai_foundry_identity_type
  user_assigned_identity_ids                 = var.ai_foundry_user_assigned_identity_ids
  api_properties                             = var.ai_foundry_api_properties
  custom_sub_domain_name                     = var.ai_foundry_custom_sub_domain_name
  disable_local_auth                         = var.ai_foundry_disable_local_auth
  dynamic_throttling_enabled                 = var.ai_foundry_dynamic_throttling_enabled
  fqdn                                       = var.ai_foundry_fqdn
  migration_token                            = var.ai_foundry_migration_token
  network_acls                               = var.ai_foundry_network_acls
  public_network_access                      = var.ai_foundry_public_network_access
  quota_limit                                = var.ai_foundry_quota_limit
  restore                                    = var.ai_foundry_restore
  restrict_outbound_network_access           = var.ai_foundry_restrict_outbound_network_access
  user_owned_storage                         = var.ai_foundry_user_owned_storage
  allow_project_management                   = var.ai_foundry_allow_project_management
  network_injections                         = var.ai_foundry_network_injections

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
  location                        = local.location
  ai_search_id                    = var.ai_search_resource_id
  cosmos_db_id                    = var.cosmos_db_resource_id
  create_ai_agent_service         = var.create_ai_agent_service
  create_project_connections      = var.create_project_connections
  storage_account_id              = var.storage_account_resource_id
  tags                            = var.tags

  depends_on = [
    module.ai_foundry
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
