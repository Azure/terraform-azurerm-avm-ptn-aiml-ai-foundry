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

- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_string.resource_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azapi_client_config.telemetry](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_base_name"></a> [base\_name](#input\_base\_name)

Description: The name prefix for the AI Foundry resources. Will be used as base\_name if base\_name is not provided.

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_ai_foundry_project_description"></a> [ai\_foundry\_project\_description](#input\_ai\_foundry\_project\_description)

Description: Description for the AI Foundry project.

Type: `string`

Default: `"AI Foundry project for agent services and AI workloads"`

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

### <a name="input_ai_search_resource_id"></a> [ai\_search\_resource\_id](#input\_ai\_search\_resource\_id)

Description: (Optional) The resource ID of an existing AI Search service to use. If not provided, a new AI Search service will be created.

Type: `string`

Default: `null`

### <a name="input_cosmos_db_resource_id"></a> [cosmos\_db\_resource\_id](#input\_cosmos\_db\_resource\_id)

Description: (Optional) The resource ID of an existing Cosmos DB account to use. If not provided, a new Cosmos DB account will be created.

Type: `string`

Default: `null`

### <a name="input_create_ai_agent_service"></a> [create\_ai\_agent\_service](#input\_create\_ai\_agent\_service)

Description: Whether to create an AI agent service using AzAPI capability hosts.

Type: `bool`

Default: `false`

### <a name="input_create_dependent_resources"></a> [create\_dependent\_resources](#input\_create\_dependent\_resources)

Description: Whether to create dependent resources such as AI Search, Cosmos DB, Key Vault, and Storage Account. If set to false, resource ids of existing resources must be provided (BYOR).

Type: `bool`

Default: `false`

### <a name="input_create_private_endpoints"></a> [create\_private\_endpoints](#input\_create\_private\_endpoints)

Description: Whether to create private endpoints for AI Foundry, Cosmos DB, Key Vault, and AI Search. If set to false, private endpoints will not be created.

Type: `bool`

Default: `false`

### <a name="input_create_project_connections"></a> [create\_project\_connections](#input\_create\_project\_connections)

Description: Whether to create connections to the AI Foundry project. If set to true, connections will be created for the dependent AI Foundry resources. If set to false, no connections will be created.

Type: `bool`

Default: `false`

### <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group)

Description: Whether to create a new resource group. Set to false to use an existing resource group specified in resource\_group\_name.

Type: `bool`

Default: `false`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

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

### <a name="input_private_dns_zone_resource_id_cosmosdb"></a> [private\_dns\_zone\_resource\_id\_cosmosdb](#input\_private\_dns\_zone\_resource\_id\_cosmosdb)

Description: (Optional) The resource ID of the existing private DNS zone for Cosmos DB.

Type: `string`

Default: `null`

### <a name="input_private_dns_zone_resource_id_keyvault"></a> [private\_dns\_zone\_resource\_id\_keyvault](#input\_private\_dns\_zone\_resource\_id\_keyvault)

Description: (Optional) The resource ID of the existing private DNS zone for Key Vault.

Type: `string`

Default: `null`

### <a name="input_private_dns_zone_resource_id_search"></a> [private\_dns\_zone\_resource\_id\_search](#input\_private\_dns\_zone\_resource\_id\_search)

Description: (Optional) The resource ID of the existing private DNS zone for AI Search.

Type: `string`

Default: `null`

### <a name="input_private_dns_zone_resource_id_storage_blob"></a> [private\_dns\_zone\_resource\_id\_storage\_blob](#input\_private\_dns\_zone\_resource\_id\_storage\_blob)

Description: (Optional) The resource ID of the existing private DNS zone for Storage Blob.

Type: `string`

Default: `null`

### <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id)

Description: (Optional) The subnet ID for private endpoints.

Type: `string`

Default: `null`

### <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id)

Description: The full resource ID of the resource group. When provided, this takes precedence over resource\_group\_name. Useful for cross-subscription deployments or when the exact resource ID is known. Format: '/subscriptions/{subscription-id}/resourceGroups/{resource-group-name}'

Type: `string`

Default: `null`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The name for the resource group. When create\_resource\_group=true, this will be the name of the new resource group. When create\_resource\_group=false, this must be the name of an existing resource group.

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
    ai_search                       = optional(string)
    cosmos_db                       = optional(string)
    key_vault                       = optional(string)
    resource_group                  = optional(string)
    storage_account                 = optional(string)
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

### <a name="input_storage_account_resource_id"></a> [storage\_account\_resource\_id](#input\_storage\_account\_resource\_id)

Description: (Optional) The resource ID of an existing storage account to use. If not provided, a new storage account will be created.

Type: `string`

Default: `null`

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

### <a name="output_ai_foundry_project_name"></a> [ai\_foundry\_project\_name](#output\_ai\_foundry\_project\_name)

Description: The name of the AI Foundry Project.

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

### <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id)

Description: The resource ID of the resource group.

### <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name)

Description: The name of the resource group.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The resource ID of the primary AI Foundry project resource.

### <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id)

Description: The resource ID of the storage account.

### <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name)

Description: The name of the storage account.

## Modules

The following Modules are called:

### <a name="module_ai_foundry"></a> [ai\_foundry](#module\_ai\_foundry)

Source: ./modules/ai-foundry

Version:

### <a name="module_ai_foundry_project"></a> [ai\_foundry\_project](#module\_ai\_foundry\_project)

Source: ./modules/ai-foundry-project

Version:

### <a name="module_dependent_resources"></a> [dependent\_resources](#module\_dependent\_resources)

Source: ./modules/dependent-resources

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
