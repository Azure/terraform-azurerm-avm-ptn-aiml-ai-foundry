<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.9)

## Resources

The following resources are used by this module:

- [azapi_resource.ai_agent_capability_host](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.ai_foundry_project](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.ai_foundry_project_connection_cosmos](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.ai_foundry_project_connection_search](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.ai_foundry_project_connection_storage](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_cosmosdb_sql_role_assignment.agent_entity_store](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_role_assignment) (resource)
- [azurerm_cosmosdb_sql_role_assignment.system_thread_message_store](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_role_assignment) (resource)
- [azurerm_cosmosdb_sql_role_assignment.thread_message_store](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_role_assignment) (resource)
- [azurerm_role_assignment.storage_blob_data_owner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [time_sleep.wait_project_identities](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_ai_agent_host_name"></a> [ai\_agent\_host\_name](#input\_ai\_agent\_host\_name)

Description: Name of the AI agent capability host

Type: `string`

### <a name="input_ai_foundry_id"></a> [ai\_foundry\_id](#input\_ai\_foundry\_id)

Description: Resource ID of the AI Foundry account

Type: `string`

### <a name="input_ai_foundry_project_description"></a> [ai\_foundry\_project\_description](#input\_ai\_foundry\_project\_description)

Description: Description for the AI Foundry project

Type: `string`

### <a name="input_ai_foundry_project_display_name"></a> [ai\_foundry\_project\_display\_name](#input\_ai\_foundry\_project\_display\_name)

Description: Display name for the AI Foundry project

Type: `string`

### <a name="input_ai_foundry_project_name"></a> [ai\_foundry\_project\_name](#input\_ai\_foundry\_project\_name)

Description: Name of the AI Foundry project

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region for deployment

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_ai_search_id"></a> [ai\_search\_id](#input\_ai\_search\_id)

Description: Resource ID of the AI Search service

Type: `string`

Default: `null`

### <a name="input_cosmos_db_id"></a> [cosmos\_db\_id](#input\_cosmos\_db\_id)

Description: Resource ID of the Cosmos DB account

Type: `string`

Default: `null`

### <a name="input_create_ai_agent_service"></a> [create\_ai\_agent\_service](#input\_create\_ai\_agent\_service)

Description: Whether to create the AI agent service

Type: `bool`

Default: `true`

### <a name="input_create_project_connections"></a> [create\_project\_connections](#input\_create\_project\_connections)

Description: Whether to create connections to the AI Foundry project. If set to true, connections will be created for the dependent AI Foundry resources. If set to false, no connections will be created.

Type: `bool`

Default: `false`

### <a name="input_storage_account_id"></a> [storage\_account\_id](#input\_storage\_account\_id)

Description: Resource ID of the Storage Account

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Tags to apply to resources

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_ai_agent_capability_host_id"></a> [ai\_agent\_capability\_host\_id](#output\_ai\_agent\_capability\_host\_id)

Description: Resource ID of the AI agent capability host

### <a name="output_ai_foundry_project_id"></a> [ai\_foundry\_project\_id](#output\_ai\_foundry\_project\_id)

Description: Resource ID of the AI Foundry project

### <a name="output_ai_foundry_project_internal_id"></a> [ai\_foundry\_project\_internal\_id](#output\_ai\_foundry\_project\_internal\_id)

Description: Internal ID of the AI Foundry project used for container naming

### <a name="output_ai_foundry_project_name"></a> [ai\_foundry\_project\_name](#output\_ai\_foundry\_project\_name)

Description: Name of the AI Foundry project

### <a name="output_ai_foundry_project_system_identity_principal_id"></a> [ai\_foundry\_project\_system\_identity\_principal\_id](#output\_ai\_foundry\_project\_system\_identity\_principal\_id)

Description: Principal ID of the AI Foundry project's system-assigned managed identity

### <a name="output_project_id_guid"></a> [project\_id\_guid](#output\_project\_id\_guid)

Description: Project ID formatted as GUID for container naming (only available when AI agent service is enabled)

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: Resource ID of the primary AI Foundry project

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->