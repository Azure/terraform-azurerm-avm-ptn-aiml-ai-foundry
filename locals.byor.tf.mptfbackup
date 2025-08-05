
locals {
  cosmosdb_secondary_regions = { for k, v in var.cosmosdb_definition : k => (var.cosmosdb_definition[k].secondary_regions == null ? [] : (
    try(length(var.cosmosdb_definition[k].secondary_regions) == 0, false) ? [
      {
        location          = local.paired_region
        zone_redundant    = false #length(local.paired_region_zones) > 1 ? true : false TODO: set this back to dynamic based on region zone availability after testing. Our subs don't have quota for zonal deployments.
        failover_priority = 1
      },
      {
        location          = var.location
        zone_redundant    = false #length(local.region_zones) > 1 ? true : false
        failover_priority = 0
      }
    ] : var.cosmosdb_definition[k].secondary_regions)
  ) }
  #################################################################
  # Key Vault specific local variables
  #################################################################
  key_vault_default_role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
  #key_vault_name = try(var.key_vault_definition.name, null) != null ? var.key_vault_definition.name : (try(var.base_name, null) != null ? "${var.base_name}-kv-${random_string.resource_token.result}" : "kv-fndry-${random_string.resource_token.result}")
  key_vault_role_assignments = { for k, v in var.key_vault_definition : k => merge(
    local.key_vault_default_role_assignments,
    var.key_vault_definition[k].role_assignments
  ) }
  #################################################################
  # Log Analytics specific local variables
  #################################################################
  log_analytics_workspace_name = length(var.law_definition) > 0 ? try(values(var.law_definition)[0].name, null) != null ? values(var.law_definition)[0].name : (try(var.base_name, null) != null ? "${var.base_name}-law" : "ai-foundry-law") : "ai-foundry-law"
  paired_region                = [for region in module.avm_utl_regions.regions : region if(lower(region.name) == lower(var.location) || (lower(region.display_name) == lower(var.location)))][0].paired_region_name
  #paired_region_zones          = local.paired_region_zones_lookup != null ? local.paired_region_zones_lookup : []
  #paired_region_zones_lookup   = [for region in module.avm_utl_regions.regions : region if(lower(region.name) == lower(local.paired_region) || (lower(region.display_name) == lower(local.paired_region)))][0].zones
  #region_zones                 = local.region_zones_lookup != null ? local.region_zones_lookup : []
  #region_zones_lookup          = [for region in module.avm_utl_regions.regions : region if(lower(region.name) == lower(var.location) || (lower(region.display_name) == lower(var.location)))][0].zones
  resource_group_name = basename(var.resource_group_resource_id) #assumes resource group id is required.
  storage_account_default_role_assignments = {
    deployment_user_blob = {
      role_definition_id_or_name = "Storage Blob Data Owner"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    deployment_user_file = {
      role_definition_id_or_name = "Storage File Data Privileged Contributor"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    deployment_user_queue = {
      role_definition_id_or_name = "Storage Queue Data Contributor"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    deployment_user_table = {
      role_definition_id_or_name = "Storage Table Data Contributor"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
  #################################################################
  # Storage Account specific local variables
  #################################################################
  #storage_account_name = try(var.storage_account_definition.name, null) != null ? var.storage_account_definition.name : (try(var.base_name, null) != null ? "${local.base_name_storage}fndrysa${random_string.resource_token.result}" : "fndrysa${random_string.resource_token.result}")
  storage_account_role_assignments = { for k, v in var.storage_account_definition : k => merge(
    local.storage_account_default_role_assignments,
    var.storage_account_definition[k].role_assignments
  ) }
}

