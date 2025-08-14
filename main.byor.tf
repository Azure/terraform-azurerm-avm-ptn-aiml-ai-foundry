
module "avm_utl_regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.2"

  recommended_filter = false
}

module "log_analytics_workspace" {
  source   = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version  = "0.4.2"
  for_each = { for k, v in var.law_definition : k => v if v.existing_resource_id == null && var.create_byor == true }

  location                                  = var.location
  name                                      = local.log_analytics_workspace_name
  resource_group_name                       = local.resource_group_name
  enable_telemetry                          = var.enable_telemetry
  log_analytics_workspace_retention_in_days = each.value.retention
  log_analytics_workspace_sku               = each.value.sku
}

module "key_vault" {
  source   = "Azure/avm-res-keyvault-vault/azurerm"
  version  = "0.10.0"
  for_each = { for k, v in var.key_vault_definition : k => v if v.existing_resource_id == null && var.create_byor == true && var.create_byor_cmk == true }

  location            = var.location
  name                = try(each.value.name, null) != null ? each.value.name : (try(var.base_name, null) != null ? "${var.base_name}-kv-${random_string.resource_token.result}" : "kv-fndry-${random_string.resource_token.result}")
  resource_group_name = local.resource_group_name
  tenant_id           = each.value.tenant_id != null ? each.value.tenant_id : data.azurerm_client_config.current.tenant_id
  diagnostic_settings = each.value.enable_diagnostic_settings ? {
    to_law = {
      name                  = "sendToLogAnalytics-kv-${random_string.resource_token.result}"
      workspace_resource_id = var.law_definition.existing_resource_id != null ? var.law_definition.existing_resource_id : module.log_analytics_workspace[0].resource_id
    }
  } : {}
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  keys = {
    cmk = {
      key_opts = [
        "decrypt",
        "encrypt",
        "sign",
        "unwrapKey",
        "verify",
        "wrapKey"
      ]
      key_type = "RSA"
      name     = "cmk"
      key_size = 2048
    }
  }
  network_acls = { #TODO check to see if we need to support custom network ACLs and if this should be deny by default.
    default_action = "Allow"
    bypass         = "AzureServices"
    # ip_rules = ["${data.http.ip.response_body}/32"]
  }
  private_endpoints = var.create_private_endpoints ? {
    "vault" = {
      private_dns_zone_resource_ids = [each.value.private_dns_zone_resource_id]
      subnet_resource_id            = var.private_endpoint_subnet_resource_id
      subresource_name              = "vault"
    }
  } : {}
  public_network_access_enabled = var.create_private_endpoints ? false : true
  role_assignments              = local.key_vault_role_assignments[each.key]
  tags                          = each.value.tags
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
  version  = "0.6.4"
  for_each = { for k, v in var.storage_account_definition : k => v if v.existing_resource_id == null && var.create_byor == true }

  location                 = var.location
  name                     = try(each.value.name, null) != null ? each.value.name : (try(var.base_name, null) != null ? "${local.base_name_storage}${lower(each.key)}fndrysa${random_string.resource_token.result}" : "${lower(each.key)}fndrysa${random_string.resource_token.result}")
  resource_group_name      = local.resource_group_name
  access_tier              = each.value.access_tier
  account_kind             = each.value.account_kind
  account_replication_type = each.value.account_replication_type
  account_tier             = each.value.account_tier
  customer_managed_key = var.create_byor_cmk ? {
    key_vault_key_id = data.azurerm_key_vault_key.byor.id
    key_vault_key_id = data.azurerm_key_vault_key.byor[0].id
    key_name         = data.azurerm_key_vault_key.byor[0].name
  } : null
  diagnostic_settings_storage_account = each.value.enable_diagnostic_settings ? {
    storage = {
      name                  = "sendToLogAnalytics-sa-${random_string.resource_token.result}"
      workspace_resource_id = var.law_definition.existing_resource_id != null ? var.law_definition.existing_resource_id : module.log_analytics_workspace[0].resource_id
      metric_categories     = ["Transaction", "Capacity"]
    }
  } : {}
  enable_telemetry = var.enable_telemetry
  network_rules = var.create_private_endpoints ? {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  } : null
  private_endpoints = var.create_private_endpoints ? {
    for endpoint in each.value.endpoints :
    endpoint.type => {
      name                          = "${try(each.value.name, null) != null ? each.value.name : (try(var.base_name, null) != null ? "${local.base_name_storage}${lower(each.key)}fndrysa${random_string.resource_token.result}" : "${lower(each.key)}fndrysa${random_string.resource_token.result}")}-${endpoint.type}-pe"
      private_dns_zone_resource_ids = [endpoint.private_dns_zone_resource_id]
      subnet_resource_id            = var.private_endpoint_subnet_resource_id
      subresource_name              = endpoint.type
    }
  } : {}
  public_network_access_enabled = var.create_private_endpoints ? false : true
  role_assignments              = local.storage_account_role_assignments[each.key] #assumes the same role assignments will be used for all storage accounts in the map.
  shared_access_key_enabled     = each.value.shared_access_key_enabled
  tags                          = each.value.tags
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
  cors_rule = each.value.cors_rule
  customer_managed_key = var.create_byor_cmk ? {
    key_vault_key_id = data.azurerm_key_vault_key.byor.id
    key_name         = data.azurerm_key_vault_key.byor.name
  } : null
  diagnostic_settings = each.value.enable_diagnostic_settings ? {
    to_law = {
      name                  = "sendToLogAnalytics-cosmosdb-${random_string.resource_token.result}"
      workspace_resource_id = var.law_definition.existing_resource_id != null ? var.law_definition.existing_resource_id : module.log_analytics_workspace[0].resource_id
      metric_categories     = ["SLI", "Requests"]
    }
  } : {}
  enable_telemetry = var.enable_telemetry
  geo_locations    = local.cosmosdb_secondary_regions[each.key]
  ip_range_filter = [
    "168.125.123.255",
    "170.0.0.0/24",                                                                 #TODO: check 0.0.0.0 for validity
    "0.0.0.0",                                                                      #Accept connections from within public Azure datacenters. https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-the-azure-portal
    "104.42.195.92", "40.76.54.131", "52.176.6.30", "52.169.50.45", "52.187.184.26" #Allow access from the Azure portal. https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-global-azure-datacenters-or-other-sources-within-azure
  ]
  local_authentication_disabled         = each.value.local_authentication_disabled
  multiple_write_locations_enabled      = each.value.multiple_write_locations_enabled
  network_acl_bypass_for_azure_services = true
  partition_merge_enabled               = each.value.partition_merge_enabled
  private_endpoints = var.create_private_endpoints ? {
    "sql" = {
      subnet_resource_id = var.private_endpoint_subnet_resource_id
      subresource_name   = "sql"
      private_dns_zone_resource_ids = [
        each.value.private_dns_zone_resource_id
      ]
    }
  } : {}
  public_network_access_enabled = each.value.public_network_access_enabled
  role_assignments              = each.value.role_assignments
  tags                          = each.value.tags
}
