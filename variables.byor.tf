variable "ai_search_definition" {
  type = map(object({
    existing_resource_id         = optional(string, null)
    name                         = optional(string)
    private_dns_zone_resource_id = optional(string, null)
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
    sku                           = optional(string, "standard")
    local_authentication_enabled  = optional(bool, true)
    partition_count               = optional(number, 1)
    replica_count                 = optional(number, 2)
    semantic_search               = optional(string, "disabled")
    hosting_mode                  = optional(string, "default")
    public_network_access_enabled = optional(bool, null)
    network_rule_set = optional(object({
      bypass   = optional(string, "None")
      ip_rules = optional(list(string), [])
    }), {})
    tags = optional(map(string), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    enable_telemetry = optional(bool, true)
  }))
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure AI Search service to be created as part of the enterprise and public knowledge services.

- `map key` - The key for the map entry. This key should match the AI project key when creating multiple projects with multiple AI search services.
  - `existing_resource_id` - (Optional) The resource ID of an existing AI Search service to use. If provided, the service will not be created and the other inputs will be ignored.
  - `name` - (Optional) The name of the AI Search service. If not provided, a name will be generated.
  - `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for AI Search. If not provided or set to null, no DNS zone group will be created.
  - `diagnostic_settings` - (Optional) A map of diagnostic settings to create. Each entry follows the AVM diagnostic_settings interface.
  - `sku` - (Optional) The SKU of the AI Search service. Default is "standard".
  - `local_authentication_enabled` - (Optional) Whether local authentication is enabled. Default is true.
  - `partition_count` - (Optional) The number of partitions for the search service. Default is 1.
  - `replica_count` - (Optional) The number of replicas for the search service. Default is 2.
  - `semantic_search` - (Optional) The semantic search tier. Possible values are "disabled", "free", or "standard". Default is "disabled".
  - `hosting_mode` - (Optional) The hosting mode for the search service. Default is "default".
  - `public_network_access_enabled` - (Optional) Overrides public network access on the search service. Default is null, in which case the value is derived from `create_private_endpoints` (disabled when private endpoints are created, enabled otherwise).
  - `network_rule_set` - (Optional) Inbound network rules applied to the search service. Only takes effect when public network access is enabled.
    - `bypass` - (Optional) Whether trusted Azure services may bypass the rules. Possible values are "None" and "AzureServices". Default is "None".
    - `ip_rules` - (Optional) List of IPv4 addresses or CIDR ranges allowed inbound access. Default is [].
  - `tags` - (Optional) Map of tags to assign to the AI Search service.
  - `role_assignments` - (Optional) Map of role assignments to create on the AI Search service. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
    - `role_definition_id_or_name` - The role definition ID or name to assign.
    - `principal_id` - The principal ID to assign the role to.
    - `description` - (Optional) Description of the role assignment.
    - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
    - `condition` - (Optional) Condition for the role assignment.
    - `condition_version` - (Optional) Version of the condition.
    - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
    - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
  - `enable_telemetry` - (Optional) Whether telemetry is enabled for the AI Search module. Default is true.
DESCRIPTION
}

variable "cosmosdb_definition" {
  type = map(object({
    existing_resource_id         = optional(string, null)
    private_dns_zone_resource_id = optional(string, null)
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
    name = optional(string)
    secondary_regions = optional(list(object({
      location          = string
      zone_redundant    = optional(bool, true)
      failover_priority = optional(number, 0)
    })), [])
    public_network_access_enabled    = optional(bool, false)
    analytical_storage_enabled       = optional(bool, false)
    automatic_failover_enabled       = optional(bool, true)
    local_authentication_disabled    = optional(bool, true)
    partition_merge_enabled          = optional(bool, false)
    multiple_write_locations_enabled = optional(bool, false)
    # Default allowlist is the Azure portal plus global Azure datacenter source IPs: https://learn.microsoft.com/azure/cosmos-db/how-to-configure-firewall
    ip_range_filter = optional(set(string), [
      "168.125.123.255",
      "170.0.0.0/24",
      "0.0.0.0",
      "104.42.195.92", "40.76.54.131", "52.176.6.30", "52.169.50.45", "52.187.184.26"
    ])
    network_acl_bypass_for_azure_services = optional(bool, true)
    network_acl_bypass_resource_ids       = optional(set(string), [])
    virtual_network_rules = optional(set(object({
      subnet_id = string
    })), [])
    analytical_storage_config = optional(object({
      schema_type = string
    }), null)
    consistency_policy = optional(object({
      max_interval_in_seconds = optional(number, 300)
      max_staleness_prefix    = optional(number, 100001)
      consistency_level       = optional(string, "Session")
    }), {})
    backup = optional(object({
      retention_in_hours  = optional(number)
      interval_in_minutes = optional(number)
      storage_redundancy  = optional(string)
      type                = optional(string)
      tier                = optional(string)
    }), {})
    capabilities = optional(set(object({
      name = string
    })), [])
    capacity = optional(object({
      total_throughput_limit = optional(number, -1)
    }), {})
    cors_rule = optional(object({
      allowed_headers    = set(string)
      allowed_methods    = set(string)
      allowed_origins    = set(string)
      exposed_headers    = set(string)
      max_age_in_seconds = optional(number, null)
    }), null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    tags = optional(map(string), {})
  }))
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure Cosmos DB account to be created for GenAI services.

- `map key` - The key for the map entry. This key should match the AI project key when creating multiple projects and multiple CosmosDB accounts.
  - `existing_resource_id` - (Optional) The resource ID of an existing Cosmos DB account to use. If provided, the account will not be created and the other inputs will be ignored.
  - `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for Cosmos DB. If not provided or set to null, no DNS zone group will be created.
  - `diagnostic_settings` - (Optional) A map of diagnostic settings to create. Each entry follows the AVM diagnostic_settings interface.
  - `name` - (Optional) The name of the Cosmos DB account. If not provided, a name will be generated.
  - `secondary_regions` - (Optional) List of secondary regions for geo-replication.
    - `location` - The Azure region for the secondary location.
    - `zone_redundant` - (Optional) Whether zone redundancy is enabled for the secondary region. Default is true.
    - `failover_priority` - (Optional) The failover priority for the secondary region. Default is 0.
  - `public_network_access_enabled` - (Optional) Whether public network access is enabled. Default is false.
  - `analytical_storage_enabled` - (Optional) Whether analytical storage is enabled. Default is `false`. Azure no longer permits enabling Analytical Storage during account creation; set this to `true` only on accounts that already had it enabled.
  - `automatic_failover_enabled` - (Optional) Whether automatic failover is enabled. Default is false.
  - `local_authentication_disabled` - (Optional) Whether local authentication is disabled. Default is true.
  - `partition_merge_enabled` - (Optional) Whether partition merge is enabled. Default is false.
  - `multiple_write_locations_enabled` - (Optional) Whether multiple write locations are enabled. Default is false.
  - `ip_range_filter` - (Optional) Set of IP addresses or CIDR ranges allowed to reach the Cosmos DB account. Defaults to the Azure portal and global Azure datacenter source IPs documented at https://learn.microsoft.com/azure/cosmos-db/how-to-configure-firewall. Set to `[]` to remove the allowlist.
  - `network_acl_bypass_for_azure_services` - (Optional) Whether Azure services can bypass the network ACLs. Default is true.
  - `network_acl_bypass_resource_ids` - (Optional) Set of resource IDs allowed to bypass the network ACLs. Default is [].
  - `virtual_network_rules` - (Optional) Set of subnets allowed to reach the Cosmos DB account. Default is [].
    - `subnet_id` - The resource ID of the subnet to allow.
  - `analytical_storage_config` - (Optional) Analytical storage configuration.
    - `schema_type` - The schema type for analytical storage.
  - `consistency_policy` - (Optional) Consistency policy configuration.
    - `max_interval_in_seconds` - (Optional) Maximum staleness interval in seconds. Default is 300.
    - `max_staleness_prefix` - (Optional) Maximum staleness prefix. Default is 100001.
    - `consistency_level` - (Optional) The consistency level. Default is "Session".
  - `backup` - (Optional) Backup configuration.
    - `retention_in_hours` - (Optional) Backup retention in hours.
    - `interval_in_minutes` - (Optional) Backup interval in minutes.
    - `storage_redundancy` - (Optional) Storage redundancy for backups.
    - `type` - (Optional) The backup type.
    - `tier` - (Optional) The backup tier.
  - `capabilities` - (Optional) Set of capabilities to enable on the Cosmos DB account.
    - `name` - The name of the capability.
  - `capacity` - (Optional) Capacity configuration.
    - `total_throughput_limit` - (Optional) Total throughput limit. Default is -1 (unlimited).
  - `cors_rule` - (Optional) CORS rule configuration.
    - `allowed_headers` - Set of allowed headers.
    - `allowed_methods` - Set of allowed HTTP methods.
    - `allowed_origins` - Set of allowed origins.
    - `exposed_headers` - Set of exposed headers.
    - `max_age_in_seconds` - (Optional) Maximum age in seconds for CORS.
  - `role_assignments` - (Optional) Map of role assignments to create on the Cosmos DB account. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
    - `role_definition_id_or_name` - The role definition ID or name to assign.
    - `principal_id` - The principal ID to assign the role to.
    - `description` - (Optional) Description of the role assignment.
    - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
    - `condition` - (Optional) Condition for the role assignment.
    - `condition_version` - (Optional) Version of the condition.
    - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
    - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
  - `tags` - (Optional) Map of tags to assign to the Cosmos DB account.
DESCRIPTION
}

variable "key_vault_definition" {
  type = map(object({
    existing_resource_id         = optional(string, null)
    name                         = optional(string)
    private_dns_zone_resource_id = optional(string, null)
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
    sku                           = optional(string, "standard")
    tenant_id                     = optional(string)
    public_network_access_enabled = optional(bool, null)
    network_acls = optional(object({
      bypass                     = optional(string, "AzureServices")
      default_action             = optional(string, "Allow")
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
    }), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    tags = optional(map(string), {})
  }))
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure Key Vault to be created for GenAI services.

- `map key` - The key for the map entry. This key should match the AI project key when creating multiple projects with multiple Key Vaults. This can be used in naming, so short alphanumeric keys are required to avoid hitting naming length limits for the Key Vault when using the base name naming option.
  - `existing_resource_id` - (Optional) The resource ID of an existing Key Vault to use. If provided, the vault will not be created and the other inputs will be ignored.
  - `name` - (Optional) The name of the Key Vault. If not provided, a name will be generated.
  - `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for Key Vault. If not provided or set to null, no DNS zone group will be created.
  - `diagnostic_settings` - (Optional) A map of diagnostic settings to create. Each entry follows the AVM diagnostic_settings interface.
  - `sku` - (Optional) The SKU of the Key Vault. Default is "standard".
  - `tenant_id` - (Optional) The tenant ID for the Key Vault. If not provided, the current tenant will be used.
  - `public_network_access_enabled` - (Optional) Overrides public network access on the Key Vault. Default is null, in which case the value is derived from `create_private_endpoints` (disabled when private endpoints are created, enabled otherwise).
  - `network_acls` - (Optional) Network access control list applied to the Key Vault. Defaults to allowing all networks with an `AzureServices` bypass, which preserves the module's previous behaviour.
    - `bypass` - (Optional) Traffic permitted to bypass the rules. Possible values are "AzureServices" and "None". Default is "AzureServices".
    - `default_action` - (Optional) Action taken when no rule matches. Possible values are "Allow" and "Deny". Default is "Allow".
    - `ip_rules` - (Optional) List of IPv4 addresses or CIDR ranges allowed access. Default is [].
    - `virtual_network_subnet_ids` - (Optional) List of subnet resource IDs allowed access. Default is [].
  - `role_assignments` - (Optional) Map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
    - `role_definition_id_or_name` - The role definition ID or name to assign.
    - `principal_id` - The principal ID to assign the role to.
    - `description` - (Optional) Description of the role assignment.
    - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
    - `condition` - (Optional) Condition for the role assignment.
    - `condition_version` - (Optional) Version of the condition.
    - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
    - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
  - `tags` - (Optional) Map of tags to assign to the Key Vault.
DESCRIPTION
}

variable "storage_account_definition" {
  type = map(object({
    existing_resource_id = optional(string, null)
    diagnostic_settings_storage_account = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
    name                     = optional(string, null)
    account_kind             = optional(string, "StorageV2")
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "ZRS")
    endpoints = optional(map(object({
      type                         = string
      private_dns_zone_resource_id = optional(string, null)
      })), {
      blob = {
        type = "blob"
      }
    })
    access_tier                   = optional(string, "Hot")
    shared_access_key_enabled     = optional(bool, false)
    public_network_access_enabled = optional(bool, null)
    network_rules = optional(object({
      bypass                     = optional(set(string), ["AzureServices"])
      default_action             = optional(string, "Deny")
      ip_rules                   = optional(set(string), [])
      virtual_network_subnet_ids = optional(set(string), [])
      private_link_access = optional(list(object({
        endpoint_resource_id = string
        endpoint_tenant_id   = optional(string)
      })), null)
    }), null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    tags = optional(map(string), {})

    #TODO:
    # Implement subservice passthrough here
  }))
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure Storage Account to be created for GenAI services.

- `map key` - The key for the map entry. This key should match the AI project key when creating multiple projects with multiple Storage Accounts. This can be used in naming, so short alphanumeric keys are required to avoid hitting naming length limits for the Storage Account when using the base name naming option.
  - `existing_resource_id` - (Optional) The resource ID of an existing Storage Account to use. If provided, the account will not be created and the other inputs will be ignored.
  - `diagnostic_settings_storage_account` - (Optional) A map of diagnostic settings to create on the storage account. Each entry follows the AVM diagnostic_settings interface.
  - `name` - (Optional) The name of the Storage Account. If not provided, a name will be generated.
  - `account_kind` - (Optional) The kind of storage account. Default is "StorageV2".
  - `account_tier` - (Optional) The performance tier of the storage account. Default is "Standard".
  - `account_replication_type` - (Optional) The replication type for the storage account. Default is "ZRS".
  - `endpoints` - (Optional) Map of endpoint configurations to enable. Default includes blob endpoint.
    - `type` - The type of endpoint (e.g., "blob", "file", "queue", "table").
    - `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for the endpoint. If not provided or set to null, no DNS zone group will be created.
  - `access_tier` - (Optional) The access tier for the storage account. Default is "Hot".
  - `shared_access_key_enabled` - (Optional) Whether shared access keys are enabled. Default is false.
  - `public_network_access_enabled` - (Optional) Overrides public network access on the Storage Account. Default is null, in which case the value is derived from `create_private_endpoints` (disabled when private endpoints are created, enabled otherwise).
  - `network_rules` - (Optional) Storage account firewall configuration. Default is null, in which case the module keeps its previous behaviour: deny-by-default with an `AzureServices` bypass when `create_private_endpoints` is true, and no network rules at all when it is false.
    - `bypass` - (Optional) Traffic permitted to bypass the rules. Any combination of "Logging", "Metrics", "AzureServices" or "None". Default is ["AzureServices"].
    - `default_action` - (Optional) Action taken when no rule matches. Possible values are "Allow" and "Deny". Default is "Deny".
    - `ip_rules` - (Optional) Set of public IPv4 addresses or CIDR ranges allowed access. RFC 1918 private ranges are not permitted by Azure. Default is [].
    - `virtual_network_subnet_ids` - (Optional) Set of subnet resource IDs allowed access. Default is [].
    - `private_link_access` - (Optional) List of resource access rules granting private link access. Default is null.
      - `endpoint_resource_id` - The resource ID granted access.
      - `endpoint_tenant_id` - (Optional) The tenant ID of the resource. Defaults to the current tenant.
  - `role_assignments` - (Optional) Map of role assignments to create on the Storage Account. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
    - `role_definition_id_or_name` - The role definition ID or name to assign.
    - `principal_id` - The principal ID to assign the role to.
    - `description` - (Optional) Description of the role assignment.
    - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
    - `condition` - (Optional) Condition for the role assignment.
    - `condition_version` - (Optional) Version of the condition.
    - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
    - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
  - `tags` - (Optional) Map of tags to assign to the Storage Account.
DESCRIPTION
}
