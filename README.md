<!-- BEGIN_TF_DOCS -->
# Azure AI Foundry Terraform Pattern Module

This Azure Verified Module (AVM) Pattern deploys a complete AI Foundry infrastructure on Azure, providing a production-ready platform for AI applications with supporting services and configurable network isolation.

## Key Features

- **AI Foundry Account & Project**: Core cognitive services with project workspace and OpenAI model deployments
- **Bring Your Own Resources (BYOR)**: Conditional deployment of Storage, Key Vault, Cosmos DB, and AI Search
- **Network Isolation**: Private endpoints and VNet integration support for enterprise security
- **Three Example Configurations**: Basic (minimal), Standard Public (full features), Standard Private (enterprise-grade)

## Architecture

The module uses a conditional deployment pattern where dependent services can be:
- **Created new** (`*_resource_id = null`) - Creates new resources (default behavior)
- **Use existing** (`*_resource_id = "/subscriptions/.../resource-id"`) - Uses provided existing resources

| Feature | Basic | Standard Public | Standard Private |
|---------|-------|-----------------|------------------|
| **AI Foundry** | ✅ Public | ✅ Public | ✅ Private |
| **Storage/Key Vault/Cosmos/Search** | ❌ Not created | ✅ New Public | ✅ New Private |
| **Private Endpoints** | ❌ | ❌ | ✅ All services |
| **VNet & Management** | ❌ | ❌ | ✅ Bastion & VM |
| **Use Case** | Development, PoC | Production | Enterprise, regulated |

## Integration

This module can be used independently or as part of the broader AI/ML platform when combined with the [AI Landing Zone Accelerator](https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone) module.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azapi_resource.ai_foundry](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.ai_model_deployment](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_private_endpoint.ai_foundry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_string.resource_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azapi_client_config.telemetry](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_ai_foundry"></a> [ai\_foundry](#input\_ai\_foundry)

Description: n/a

Type:

```hcl
object({
    name                     = optional(string, null)
    disable_local_auth       = optional(bool, false)
    allow_project_management = optional(bool, true)
    create_ai_agent_service  = optional(bool, false)
    network_injections = optional(list(object({
      scenario                   = optional(string, "agent")
      subnetArmId                = string
      useMicrosoftManagedNetwork = optional(bool, false)
    })), null)
    private_dns_zone_resource_id = optional(string, null)
    sku                          = optional(string, "S0")
  })
```

### <a name="input_base_name"></a> [base\_name](#input\_base\_name)

Description: The name prefix for the AI Foundry resources.

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_resource_group_resource_id"></a> [resource\_group\_resource\_id](#input\_resource\_group\_resource\_id)

Description: The resource group resource id where the module resources will be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_agent_subnet_resource_id"></a> [agent\_subnet\_resource\_id](#input\_agent\_subnet\_resource\_id)

Description: (Optional) The subnet ID for the AI agent service. If not provided, managed network will be used for the AI agent service. If provided, the AI agent service will be deployed in the specified subnet.

Type: `string`

Default: `null`

### <a name="input_ai_model_deployments"></a> [ai\_model\_deployments](#input\_ai\_model\_deployments)

Description: Configuration for AI model deployments (including OpenAI). Each deployment includes:
- `name` - The name of the deployment
- `rai_policy_name` - (Optional) The name of the RAI policy
- `version_upgrade_option` - (Optional) How to handle version upgrades (default: "OnceNewDefaultVersionAvailable")
- `model` - The model configuration:
  - `format` - The format of the model (e.g., "OpenAI")
  - `name` - The name of the model to deploy
  - `version` - The version of the model
- `scale` - The scaling configuration:
  - `type` - The scaling type (e.g., "Standard")
  - `capacity` - (Optional) The capacity of the deployment
  - `family` - (Optional) The family of the deployment
  - `size` - (Optional) The size of the deployment
  - `tier` - (Optional) The pricing tier for the deployment

Type:

```hcl
map(object({
    name                   = string
    rai_policy_name        = optional(string)
    version_upgrade_option = optional(string, "OnceNewDefaultVersionAvailable")
    model = object({
      format  = string
      name    = string
      version = string
    })
    scale = object({
      capacity = optional(number)
      family   = optional(string)
      size     = optional(string)
      tier     = optional(string)
      type     = string
    })
  }))
```

Default: `{}`

### <a name="input_ai_projects"></a> [ai\_projects](#input\_ai\_projects)

Description: Map of AI Foundry projects with their configurations. Each project can have its own settings. Map keys should match the dependent resources keys when creating connections.

Type:

```hcl
map(object({
    name         = string
    sku          = optional(string, "S0")
    display_name = string
    description  = string
    cosmos_db_connection = optional(object({
      existing_resource_id = optional(string, null)
      new_resource_map_key = optional(string, null)
    }), {})
    ai_search_connection = optional(object({
      existing_resource_id = optional(string, null)
      new_resource_map_key = optional(string, null)
    }), {})
    key_vault_connection = optional(object({
      existing_resource_id = optional(string, null)
      new_resource_map_key = optional(string, null)
    }), {})
    storage_account_connection = optional(object({
      existing_resource_id = optional(string, null)
      new_resource_map_key = optional(string, null)
    }), {})
  }))
```

Default: `{}`

### <a name="input_ai_search_definition"></a> [ai\_search\_definition](#input\_ai\_search\_definition)

Description: Configuration object for the Azure AI Search service to be created as part of the enterprise and public knowledge services.

- `map key` - The key for the map entry. This key should match the AI project key when creating multiple projects with multiple AI search services.
  - `existing_resource_id` - (Optional) The resource ID of an existing AI Search service to use. If provided, the service will not be created and the other inputs will be ignored.
  - `name` - (Optional) The name of the AI Search service. If not provided, a name will be generated.
  - `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for AI Search. If not provided, a private endpoint will not be created.
  - `sku` - (Optional) The SKU of the AI Search service. Default is "standard".
  - `local_authentication_enabled` - (Optional) Whether local authentication is enabled. Default is true.
  - `partition_count` - (Optional) The number of partitions for the search service. Default is 1.
  - `replica_count` - (Optional) The number of replicas for the search service. Default is 2.
  - `semantic_search_sku` - (Optional) The SKU for semantic search capabilities. Default is "standard".
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

Type:

```hcl
map(object({
    existing_resource_id         = optional(string, null)
    name                         = optional(string)
    private_dns_zone_resource_id = optional(string, null)
    enable_diagnostic_settings   = optional(bool, true)
    sku                          = optional(string, "standard")
    local_authentication_enabled = optional(bool, true)
    partition_count              = optional(number, 1)
    replica_count                = optional(number, 2)
    semantic_search_sku          = optional(string, "standard")
    tags                         = optional(map(string), {})
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
```

Default: `{}`

### <a name="input_cosmosdb_definition"></a> [cosmosdb\_definition](#input\_cosmosdb\_definition)

Description: Configuration object for the Azure Cosmos DB account to be created for GenAI services.

- `map key` - The key for the map entry. This key should match the AI project key when creating multiple projects and multiple CosmosDB accounts.
  - `existing_resource_id` - (Optional) The resource ID of an existing Cosmos DB account to use. If provided, the account will not be created and the other inputs will be ignored.
  - `name` - (Optional) The name of the Cosmos DB account. If not provided, a name will be generated.
  - `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for Cosmos DB. If one is not provided a private endpoint will not be created.
  - `secondary_regions` - (Optional) List of secondary regions for geo-replication.
    - `location` - The Azure region for the secondary location.
    - `zone_redundant` - (Optional) Whether zone redundancy is enabled for the secondary region. Default is true.
    - `failover_priority` - (Optional) The failover priority for the secondary region. Default is 0.
  - `public_network_access_enabled` - (Optional) Whether public network access is enabled. Default is false.
  - `analytical_storage_enabled` - (Optional) Whether analytical storage is enabled. Default is true.
  - `automatic_failover_enabled` - (Optional) Whether automatic failover is enabled. Default is false.
  - `local_authentication_disabled` - (Optional) Whether local authentication is disabled. Default is true.
  - `partition_merge_enabled` - (Optional) Whether partition merge is enabled. Default is false.
  - `multiple_write_locations_enabled` - (Optional) Whether multiple write locations are enabled. Default is false.
  - `analytical_storage_config` - (Optional) Analytical storage configuration.
    - `schema_type` - The schema type for analytical storage.
  - `consistency_policy` - (Optional) Consistency policy configuration.
    - `max_interval_in_seconds` - (Optional) Maximum staleness interval in seconds. Default is 300.
    - `max_staleness_prefix` - (Optional) Maximum staleness prefix. Default is 100001.
    - `consistency_level` - (Optional) The consistency level. Default is "BoundedStaleness".
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

Type:

```hcl
map(object({
    existing_resource_id         = optional(string, null)
    private_dns_zone_resource_id = optional(string, null)
    enable_diagnostic_settings   = optional(bool, true)
    name                         = optional(string)
    secondary_regions = optional(list(object({
      location          = string
      zone_redundant    = optional(bool, true)
      failover_priority = optional(number, 0)
    })), [])
    public_network_access_enabled    = optional(bool, false)
    analytical_storage_enabled       = optional(bool, true)
    automatic_failover_enabled       = optional(bool, true)
    local_authentication_disabled    = optional(bool, true)
    partition_merge_enabled          = optional(bool, false)
    multiple_write_locations_enabled = optional(bool, false)
    analytical_storage_config = optional(object({
      schema_type = string
    }), null)
    consistency_policy = optional(object({
      max_interval_in_seconds = optional(number, 300)
      max_staleness_prefix    = optional(number, 100001)
      consistency_level       = optional(string, "BoundedStaleness")
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
```

Default: `{}`

### <a name="input_create_ai_agent_service"></a> [create\_ai\_agent\_service](#input\_create\_ai\_agent\_service)

Description: Whether to create an AI agent service using AzAPI capability hosts.

Type: `bool`

Default: `false`

### <a name="input_create_private_endpoints"></a> [create\_private\_endpoints](#input\_create\_private\_endpoints)

Description: Whether to create private endpoints for AI Foundry, Cosmos DB, Key Vault, and AI Search. If set to false, private endpoints will not be created.

Type: `bool`

Default: `false`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_include_dependent_resources"></a> [include\_dependent\_resources](#input\_include\_dependent\_resources)

Description: Whether to include dependent resources such as AI Search, Cosmos DB, Key Vault, and Storage Account in this deployment. If set to false, these resources will not be created or linked, and the module will only create the AI Foundry account and project.

Type: `bool`

Default: `true`

### <a name="input_key_vault_definition"></a> [key\_vault\_definition](#input\_key\_vault\_definition)

Description: Configuration object for the Azure Key Vault to be created for GenAI services.

- `map key` - The key for the map entry. This key should match the AI project key when creating multiple projects with multiple Key Vaults. This can be used in naming, so short alphanumeric keys are required to avoid hitting naming length limits for the Key Vault when using the base name naming option.
  - `existing_resource_id` - (Optional) The resource ID of an existing Key Vault to use. If provided, the vault will not be created and the other inputs will be ignored.
  - `name` - (Optional) The name of the Key Vault. If not provided, a name will be generated.
  - `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for Key Vault. If one is not provided a private endpoint will not be created.
  - `sku` - (Optional) The SKU of the Key Vault. Default is "standard".
  - `tenant_id` - (Optional) The tenant ID for the Key Vault. If not provided, the current tenant will be used.
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

Type:

```hcl
map(object({
    existing_resource_id         = optional(string, null)
    name                         = optional(string)
    private_dns_zone_resource_id = optional(string, null)
    enable_diagnostic_settings   = optional(bool, true)
    sku                          = optional(string, "standard")
    tenant_id                    = optional(string)
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
```

Default: `{}`

### <a name="input_law_definition"></a> [law\_definition](#input\_law\_definition)

Description: Configuration object for the Log Analytics Workspace to be created for monitoring and logging.

- `existing_resource_id` - (Optional) The resource ID of an existing Log Analytics Workspace to use. If provided, the workspace will not be created and the other inputs will be ignored.
- `name` - (Optional) The name of the Log Analytics Workspace. If not provided, a name will be generated.
- `retention` - (Optional) The data retention period in days for the workspace. Default is 30.
- `sku` - (Optional) The SKU of the Log Analytics Workspace. Default is "PerGB2018".
- `tags` - (Optional) Map of tags to assign to the Log Analytics Workspace.

Type:

```hcl
object({
    existing_resource_id = optional(string)
    name                 = optional(string)
    retention            = optional(number, 30)
    sku                  = optional(string, "PerGB2018")
    tags                 = optional(map(string), {})
  })
```

Default: `{}`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `"CanNotDelete"` and `"ReadOnly"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_private_dns_zone_resource_id_ai_foundry"></a> [private\_dns\_zone\_resource\_id\_ai\_foundry](#input\_private\_dns\_zone\_resource\_id\_ai\_foundry)

Description: (Optional) The resource ID of the existing private DNS zone for AI Foundry.

Type: `string`

Default: `null`

### <a name="input_private_endpoint_subnet_resource_id"></a> [private\_endpoint\_subnet\_resource\_id](#input\_private\_endpoint\_subnet\_resource\_id)

Description: (Optional) The subnet ID for private endpoints.

Type: `string`

Default: `null`

### <a name="input_resource_names"></a> [resource\_names](#input\_resource\_names)

Description: Custom names for each resource. If not provided, names will be generated using base\_name or name.

Type:

```hcl
object({
    ai_agent_host                   = optional(string)
    ai_foundry                      = optional(string)
    ai_foundry_project              = optional(string)
    ai_foundry_project_display_name = optional(string)
  })
```

Default: `{}`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.
- `delegated_managed_identity_resource_id` - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.
- `principal_type` - The type of the principal\_id. Possible values are `User`, `Group` and `ServicePrincipal`. Changing this forces a new resource to be created. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_storage_account_definition"></a> [storage\_account\_definition](#input\_storage\_account\_definition)

Description: Configuration object for the Azure Storage Account to be created for GenAI services.

- `map key` - The key for the map entry. This key should match the AI project key when creating multiple projects with multiple Storage Accounts. This can be used in naming, so short alphanumeric keys are required to avoid hitting naming length limits for the Key Vault when using the base name naming option.
  - `existing_resource_id` - (Optional) The resource ID of an existing Storage Account to use. If provided, the account will not be created and the other inputs will be ignored.
  - `name` - (Optional) The name of the Storage Account. If not provided, a name will be generated.
  - `account_kind` - (Optional) The kind of storage account. Default is "StorageV2".
  - `account_tier` - (Optional) The performance tier of the storage account. Default is "Standard".
  - `account_replication_type` - (Optional) The replication type for the storage account. Default is "GRS".
  - `endpoints` - (Optional) Map of endpoint configurations to enable. Default includes blob endpoint.
    - `type` - The type of endpoint (e.g., "blob", "file", "queue", "table").
    - `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for the endpoint. If not provided, a private endpoint will not be created.
  - `access_tier` - (Optional) The access tier for the storage account. Default is "Hot".
  - `shared_access_key_enabled` - (Optional) Whether shared access keys are enabled. Default is true.
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

Type:

```hcl
map(object({
    existing_resource_id       = optional(string, null)
    enable_diagnostic_settings = optional(bool, true)
    name                       = optional(string, null)
    account_kind               = optional(string, "StorageV2")
    account_tier               = optional(string, "Standard")
    account_replication_type   = optional(string, "GRS")
    endpoints = optional(map(object({
      type                         = string
      private_dns_zone_resource_id = optional(string, null)
      })), {
      blob = {
        type = "blob"
      }
    })
    access_tier               = optional(string, "Hot")
    shared_access_key_enabled = optional(bool, true)
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
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags to be applied to all resources.

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_ai_agent_service_id"></a> [ai\_agent\_service\_id](#output\_ai\_agent\_service\_id)

Description: The resource ID of the AI agent capability host.

### <a name="output_ai_foundry_id"></a> [ai\_foundry\_id](#output\_ai\_foundry\_id)

Description: The resource ID of the AI Foundry account.

### <a name="output_ai_foundry_name"></a> [ai\_foundry\_name](#output\_ai\_foundry\_name)

Description: The name of the AI Foundry account.

### <a name="output_ai_foundry_project_id"></a> [ai\_foundry\_project\_id](#output\_ai\_foundry\_project\_id)

Description: The resource ID of the AI Foundry Project.

### <a name="output_ai_foundry_project_internal_id"></a> [ai\_foundry\_project\_internal\_id](#output\_ai\_foundry\_project\_internal\_id)

Description: The internal ID of the AI Foundry project used for container naming.

### <a name="output_ai_foundry_project_name"></a> [ai\_foundry\_project\_name](#output\_ai\_foundry\_project\_name)

Description: The name of the AI Foundry Project.

### <a name="output_ai_foundry_project_system_identity_principal_id"></a> [ai\_foundry\_project\_system\_identity\_principal\_id](#output\_ai\_foundry\_project\_system\_identity\_principal\_id)

Description: The principal ID of the AI Foundry project's system-assigned managed identity.

### <a name="output_ai_model_deployment_ids"></a> [ai\_model\_deployment\_ids](#output\_ai\_model\_deployment\_ids)

Description: The resource IDs of all AI model deployments.

### <a name="output_ai_search_id"></a> [ai\_search\_id](#output\_ai\_search\_id)

Description: The resource ID of the AI Search service.

### <a name="output_ai_search_name"></a> [ai\_search\_name](#output\_ai\_search\_name)

Description: The name of the AI Search service.

### <a name="output_cosmos_db_id"></a> [cosmos\_db\_id](#output\_cosmos\_db\_id)

Description: The resource ID of the Cosmos DB account.

### <a name="output_cosmos_db_name"></a> [cosmos\_db\_name](#output\_cosmos\_db\_name)

Description: The name of the Cosmos DB account.

### <a name="output_key_vault_id"></a> [key\_vault\_id](#output\_key\_vault\_id)

Description: The resource ID of the Key Vault.

### <a name="output_key_vault_name"></a> [key\_vault\_name](#output\_key\_vault\_name)

Description: The name of the Key Vault.

### <a name="output_project_id_guid"></a> [project\_id\_guid](#output\_project\_id\_guid)

Description: The project ID formatted as GUID for container naming (only available when AI agent service is enabled).

### <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id)

Description: The resource ID of the resource group.

### <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name)

Description: The name of the resource group.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The resource IDs of the AI Foundry resource.

### <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id)

Description: The resource ID of the storage account.

### <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name)

Description: The name of the storage account.

## Modules

The following Modules are called:

### <a name="module_ai_foundry_project"></a> [ai\_foundry\_project](#module\_ai\_foundry\_project)

Source: ./modules/ai-foundry-project

Version:

### <a name="module_ai_search"></a> [ai\_search](#module\_ai\_search)

Source: Azure/avm-res-search-searchservice/azurerm

Version: 0.1.5

### <a name="module_avm_utl_regions"></a> [avm\_utl\_regions](#module\_avm\_utl\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: 0.5.2

### <a name="module_cosmosdb"></a> [cosmosdb](#module\_cosmosdb)

Source: Azure/avm-res-documentdb-databaseaccount/azurerm

Version: 0.8.0

### <a name="module_key_vault"></a> [key\_vault](#module\_key\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: 0.10.0

### <a name="module_log_analytics_workspace"></a> [log\_analytics\_workspace](#module\_log\_analytics\_workspace)

Source: Azure/avm-res-operationalinsights-workspace/azurerm

Version: 0.4.2

### <a name="module_storage_account"></a> [storage\_account](#module\_storage\_account)

Source: Azure/avm-res-storage-storageaccount/azurerm

Version: 0.6.3

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->