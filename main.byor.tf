module "avm_utl_regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

  enable_telemetry = var.enable_telemetry
}

module "key_vault" {
  source   = "Azure/avm-res-keyvault-vault/azurerm"
  version  = "0.11.0"
  for_each = { for k, v in var.key_vault_definition : k => v if v.existing_resource_id == null && var.create_byor == true }

  location                        = var.location
  name                            = try(each.value.name, null) != null ? each.value.name : (try(var.base_name, null) != null ? "${var.base_name}-kv-${random_string.resource_token.result}" : "kv-fndry-${random_string.resource_token.result}")
  resource_group_name             = local.resource_group_name
  tenant_id                       = each.value.tenant_id != null ? each.value.tenant_id : data.azurerm_client_config.current.tenant_id
  diagnostic_settings             = each.value.diagnostic_settings
  enable_telemetry                = var.enable_telemetry
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  network_acls                    = each.value.network_acls
  private_endpoints = var.create_private_endpoints ? {
    "vault" = {
      private_dns_zone_resource_ids = each.value.private_dns_zone_resource_id != null ? [each.value.private_dns_zone_resource_id] : []
      subnet_resource_id            = var.private_endpoint_subnet_resource_id
      subresource_name              = "vault"
    }
  } : {}
  private_endpoints_manage_dns_zone_group = var.private_endpoints_manage_dns_zone_groups
  public_network_access_enabled           = each.value.public_network_access_enabled != null ? each.value.public_network_access_enabled : (var.create_private_endpoints ? false : true)
  role_assignments                        = local.key_vault_role_assignments[each.key]
  tags                                    = each.value.tags
  wait_for_rbac_before_key_operations = {
    create = "60s"
  }
  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
}

#TODO:
# Implement subservice passthrough in variables and here
# removing for testing PE DNS zone strategy when platform flag is false

module "storage_account" {
  source   = "Azure/avm-res-storage-storageaccount/azurerm"
  version  = "0.6.9"
  for_each = { for k, v in var.storage_account_definition : k => v if v.existing_resource_id == null && var.create_byor == true }

  location                            = var.location
  name                                = try(each.value.name, null) != null ? each.value.name : (try(var.base_name, null) != null ? "${local.base_name_storage}${lower(each.key)}fndrysa${random_string.resource_token.result}" : "${lower(each.key)}fndrysa${random_string.resource_token.result}")
  resource_group_name                 = local.resource_group_name
  access_tier                         = each.value.access_tier
  account_kind                        = each.value.account_kind
  account_replication_type            = each.value.account_replication_type
  account_tier                        = each.value.account_tier
  diagnostic_settings_storage_account = each.value.diagnostic_settings_storage_account
  enable_telemetry                    = var.enable_telemetry
  network_rules                       = local.storage_account_network_rules[each.key]
  private_endpoints = var.create_private_endpoints ? {
    for endpoint in each.value.endpoints :
    endpoint.type => {
      name                          = "${try(each.value.name, null) != null ? each.value.name : (try(var.base_name, null) != null ? "${local.base_name_storage}${lower(each.key)}fndrysa${random_string.resource_token.result}" : "${lower(each.key)}fndrysa${random_string.resource_token.result}")}-${endpoint.type}-pe"
      private_dns_zone_resource_ids = endpoint.private_dns_zone_resource_id != null ? [endpoint.private_dns_zone_resource_id] : []
      subnet_resource_id            = var.private_endpoint_subnet_resource_id
      subresource_name              = endpoint.type
    }
  } : {}
  private_endpoints_manage_dns_zone_group = var.private_endpoints_manage_dns_zone_groups
  public_network_access_enabled           = each.value.public_network_access_enabled != null ? each.value.public_network_access_enabled : (var.create_private_endpoints ? false : true)
  role_assignments                        = local.storage_account_role_assignments[each.key] #assumes the same role assignments will be used for all storage accounts in the map.
  shared_access_key_enabled               = each.value.shared_access_key_enabled
  tags                                    = merge(var.tags, each.value.tags)
}

module "cosmosdb" {
  source   = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version  = "0.10.0"
  for_each = { for k, v in var.cosmosdb_definition : k => v if v.existing_resource_id == null && var.create_byor == true }

  location                   = var.location
  name                       = try(each.value.name, null) != null ? each.value.name : (try(var.base_name, null) != null ? "${var.base_name}-${each.key}-foundry-cosmosdb-${random_string.resource_token.result}" : "${each.key}-foundry-cosmosdb-${random_string.resource_token.result}")
  resource_group_name        = local.resource_group_name
  analytical_storage_config  = each.value.analytical_storage_config
  analytical_storage_enabled = each.value.analytical_storage_enabled
  automatic_failover_enabled = each.value.automatic_failover_enabled
  capacity = {
    total_throughput_limit = each.value.capacity.total_throughput_limit
  }
  consistency_policy = {
    consistency_level       = each.value.consistency_policy.consistency_level
    max_interval_in_seconds = each.value.consistency_policy.max_interval_in_seconds
    max_staleness_prefix    = each.value.consistency_policy.max_staleness_prefix
  }
  cors_rule                             = each.value.cors_rule
  diagnostic_settings                   = each.value.diagnostic_settings
  enable_telemetry                      = var.enable_telemetry
  geo_locations                         = local.cosmosdb_secondary_regions[each.key]
  ip_range_filter                       = each.value.ip_range_filter
  local_authentication_disabled         = each.value.local_authentication_disabled
  multiple_write_locations_enabled      = each.value.multiple_write_locations_enabled
  network_acl_bypass_for_azure_services = each.value.network_acl_bypass_for_azure_services
  network_acl_bypass_resource_ids       = each.value.network_acl_bypass_resource_ids
  partition_merge_enabled               = each.value.partition_merge_enabled
  private_endpoints = var.create_private_endpoints ? {
    "sql" = {
      subnet_resource_id = var.private_endpoint_subnet_resource_id
      subresource_name   = "sql"
      private_dns_zone_resource_ids = each.value.private_dns_zone_resource_id != null ? [
        each.value.private_dns_zone_resource_id
      ] : []
    }
  } : {}
  private_endpoints_manage_dns_zone_group = var.private_endpoints_manage_dns_zone_groups
  public_network_access_enabled           = each.value.public_network_access_enabled
  role_assignments                        = each.value.role_assignments
  tags                                    = merge(var.tags, each.value.tags)
  virtual_network_rules                   = each.value.virtual_network_rules
}
