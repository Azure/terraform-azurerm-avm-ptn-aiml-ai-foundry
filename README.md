<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-template

This is a template repo for Terraform Azure Verified Modules.

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

- [azapi_resource.ai_agent_capability_host](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.ai_foundry_project](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_private_endpoint.ai_foundry_project](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azapi_client_config.telemetry](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_cosmosdb_account.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/cosmosdb_account) (data source)
- [azurerm_key_vault.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) (data source)
- [azurerm_search_service.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/search_service) (data source)
- [azurerm_storage_account.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name prefix for the AI Foundry resources.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_ai_agent_host_name"></a> [ai\_agent\_host\_name](#input\_ai\_agent\_host\_name)

Description: The name of the AI agent capability host. If not provided, will use pattern name with suffix.

Type: `string`

Default: `null`

### <a name="input_ai_agent_subnet_resource_id"></a> [ai\_agent\_subnet\_resource\_id](#input\_ai\_agent\_subnet\_resource\_id)

Description: The resource ID of the subnet for the AI agent service. When provided, enables private networking.

Type: `string`

Default: `null`

### <a name="input_ai_foundry_project_description"></a> [ai\_foundry\_project\_description](#input\_ai\_foundry\_project\_description)

Description: Description for the AI Foundry project.

Type: `string`

Default: `"AI Foundry project for agent services and AI workloads"`

### <a name="input_ai_foundry_project_display_name"></a> [ai\_foundry\_project\_display\_name](#input\_ai\_foundry\_project\_display\_name)

Description: The display/friendly name of the AI Foundry project. If not provided, will use a default name.

Type: `string`

Default: `null`

### <a name="input_ai_foundry_project_name"></a> [ai\_foundry\_project\_name](#input\_ai\_foundry\_project\_name)

Description: The name of the AI Foundry project. If not provided, will use pattern name with suffix.

Type: `string`

Default: `null`

### <a name="input_ai_foundry_project_private_endpoints"></a> [ai\_foundry\_project\_private\_endpoints](#input\_ai\_foundry\_project\_private\_endpoints)

Description: Private endpoint configuration for the AI Foundry Project.

Type:

```hcl
map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

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

### <a name="input_ai_search_private_endpoints"></a> [ai\_search\_private\_endpoints](#input\_ai\_search\_private\_endpoints)

Description: Private endpoint configuration for the AI Search service.

Type:

```hcl
map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

### <a name="input_ai_services_private_endpoints"></a> [ai\_services\_private\_endpoints](#input\_ai\_services\_private\_endpoints)

Description: Private endpoint configuration for the AI Services account.

Type:

```hcl
map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

### <a name="input_application_insights_id"></a> [application\_insights\_id](#input\_application\_insights\_id)

Description: The resource ID of the Application Insights instance. Required for AI Foundry workspaces.

Type: `string`

Default: `null`

### <a name="input_cosmos_db_private_endpoints"></a> [cosmos\_db\_private\_endpoints](#input\_cosmos\_db\_private\_endpoints)

Description: Private endpoint configuration for the Cosmos DB account.

Type:

```hcl
map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

### <a name="input_create_ai_agent_service"></a> [create\_ai\_agent\_service](#input\_create\_ai\_agent\_service)

Description: Whether to create an AI agent service using AzAPI capability hosts.

Type: `bool`

Default: `true`

### <a name="input_create_ai_foundry_project"></a> [create\_ai\_foundry\_project](#input\_create\_ai\_foundry\_project)

Description: Whether to create an AI Foundry project workspace.

Type: `bool`

Default: `true`

### <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key)

Description: A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.

Type:

```hcl
object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
```

Default: `null`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.

Type:

```hcl
map(object({
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
  }))
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_existing_ai_search_resource_id"></a> [existing\_ai\_search\_resource\_id](#input\_existing\_ai\_search\_resource\_id)

Description: (Optional) The resource ID of an existing AI Search service to use. If not provided, a new AI Search service will be created.

Type: `string`

Default: `null`

### <a name="input_existing_cosmos_db_resource_id"></a> [existing\_cosmos\_db\_resource\_id](#input\_existing\_cosmos\_db\_resource\_id)

Description: (Optional) The resource ID of an existing Cosmos DB account to use. If not provided, a new Cosmos DB account will be created.

Type: `string`

Default: `null`

### <a name="input_existing_key_vault_resource_id"></a> [existing\_key\_vault\_resource\_id](#input\_existing\_key\_vault\_resource\_id)

Description: (Optional) The resource ID of an existing Key Vault to use. If not provided, a new Key Vault will be created.

Type: `string`

Default: `null`

### <a name="input_existing_storage_account_resource_id"></a> [existing\_storage\_account\_resource\_id](#input\_existing\_storage\_account\_resource\_id)

Description: (Optional) The resource ID of an existing storage account to use. If not provided, a new storage account will be created.

Type: `string`

Default: `null`

### <a name="input_key_vault_private_endpoints"></a> [key\_vault\_private\_endpoints](#input\_key\_vault\_private\_endpoints)

Description: Private endpoint configuration for the Key Vault.

Type:

```hcl
map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id)

Description: The resource ID of the Log Analytics workspace for Container App Environment.

Type: `string`

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description: Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
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

### <a name="input_storage_private_endpoints"></a> [storage\_private\_endpoints](#input\_storage\_private\_endpoints)

Description: Private endpoint configuration for the Storage Account.

Type:

```hcl
map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

### <a name="input_subnet_resource_id"></a> [subnet\_resource\_id](#input\_subnet\_resource\_id)

Description: The resource ID of the subnet where private endpoints will be created.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

### <a name="input_virtual_network_resource_id"></a> [virtual\_network\_resource\_id](#input\_virtual\_network\_resource\_id)

Description: The resource ID of the virtual network where private endpoints will be created.

Type: `string`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_ai_agent_environment_id"></a> [ai\_agent\_environment\_id](#output\_ai\_agent\_environment\_id)

Description: DEPRECATED: Container App Environment is managed internally by capability host.

### <a name="output_ai_agent_service_fqdn"></a> [ai\_agent\_service\_fqdn](#output\_ai\_agent\_service\_fqdn)

Description: The FQDN of the AI agent service (if available from capability host).

### <a name="output_ai_agent_service_id"></a> [ai\_agent\_service\_id](#output\_ai\_agent\_service\_id)

Description: The resource ID of the AI agent capability host.

### <a name="output_ai_agent_service_name"></a> [ai\_agent\_service\_name](#output\_ai\_agent\_service\_name)

Description: The name of the AI agent capability host.

### <a name="output_ai_foundry_hub_id"></a> [ai\_foundry\_hub\_id](#output\_ai\_foundry\_hub\_id)

Description: DEPRECATED: AI Foundry Hub is no longer created. Use ai\_foundry\_project\_id instead.

### <a name="output_ai_foundry_hub_name"></a> [ai\_foundry\_hub\_name](#output\_ai\_foundry\_hub\_name)

Description: DEPRECATED: AI Foundry Hub is no longer created. Use ai\_foundry\_project\_name instead.

### <a name="output_ai_foundry_hub_private_endpoints"></a> [ai\_foundry\_hub\_private\_endpoints](#output\_ai\_foundry\_hub\_private\_endpoints)

Description: DEPRECATED: AI Foundry Hub is no longer created.

### <a name="output_ai_foundry_hub_workspace_url"></a> [ai\_foundry\_hub\_workspace\_url](#output\_ai\_foundry\_hub\_workspace\_url)

Description: DEPRECATED: AI Foundry Hub is no longer created. Use ai\_foundry\_project\_url instead.

### <a name="output_ai_foundry_project_id"></a> [ai\_foundry\_project\_id](#output\_ai\_foundry\_project\_id)

Description: The resource ID of the AI Foundry Project.

### <a name="output_ai_foundry_project_name"></a> [ai\_foundry\_project\_name](#output\_ai\_foundry\_project\_name)

Description: The name of the AI Foundry Project.

### <a name="output_ai_foundry_project_private_endpoints"></a> [ai\_foundry\_project\_private\_endpoints](#output\_ai\_foundry\_project\_private\_endpoints)

Description: A map of private endpoints created for the AI Foundry Project (via AI Services).

### <a name="output_ai_foundry_project_workspace_url"></a> [ai\_foundry\_project\_workspace\_url](#output\_ai\_foundry\_project\_workspace\_url)

Description: The project URL of the AI Foundry Project.

### <a name="output_ai_search"></a> [ai\_search](#output\_ai\_search)

Description: The AI Search service used for vector search and retrieval.

### <a name="output_ai_services"></a> [ai\_services](#output\_ai\_services)

Description: The AI Services account with OpenAI and other AI models.

### <a name="output_cognitive_services"></a> [cognitive\_services](#output\_cognitive\_services)

Description: The AI Services account (legacy name for backward compatibility).

### <a name="output_connection_info"></a> [connection\_info](#output\_connection\_info)

Description: Connection information for integrating with the AI Foundry services.

### <a name="output_cosmos_db"></a> [cosmos\_db](#output\_cosmos\_db)

Description: The Cosmos DB account used for AI Foundry data storage.

### <a name="output_key_vault"></a> [key\_vault](#output\_key\_vault)

Description: The Key Vault used for secrets management.

### <a name="output_managed_identities"></a> [managed\_identities](#output\_managed\_identities)

Description: Managed identities created for the AI Foundry services.

### <a name="output_private_endpoints"></a> [private\_endpoints](#output\_private\_endpoints)

Description: All private endpoints created for the AI Foundry services.

### <a name="output_resource_group"></a> [resource\_group](#output\_resource\_group)

Description: The resource group containing all AI Foundry resources.

### <a name="output_storage_account"></a> [storage\_account](#output\_storage\_account)

Description: The storage account used for AI Foundry workloads.

## Modules

The following Modules are called:

### <a name="module_ai_search"></a> [ai\_search](#module\_ai\_search)

Source: Azure/avm-res-search-searchservice/azurerm

Version: ~> 0.1.5

### <a name="module_ai_services"></a> [ai\_services](#module\_ai\_services)

Source: Azure/avm-res-cognitiveservices-account/azurerm

Version: ~> 0.7.1

### <a name="module_cosmos_db"></a> [cosmos\_db](#module\_cosmos\_db)

Source: Azure/avm-res-documentdb-databaseaccount/azurerm

Version: ~> 0.8.0

### <a name="module_key_vault"></a> [key\_vault](#module\_key\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: ~> 0.10.0

### <a name="module_storage_account"></a> [storage\_account](#module\_storage\_account)

Source: Azure/avm-res-storage-storageaccount/azurerm

Version: ~> 0.6.3

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->