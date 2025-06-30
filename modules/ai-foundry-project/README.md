<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

## Resources

The following resources are used by this module:

- [azapi_resource.ai_agent_capability_host](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.ai_foundry_project](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.ai_foundry_project_connection_cosmos](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.ai_foundry_project_connection_search](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.ai_foundry_project_connection_storage](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)

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

### <a name="input_ai_search_id"></a> [ai\_search\_id](#input\_ai\_search\_id)

Description: Resource ID of the AI Search service

Type: `string`

### <a name="input_ai_search_name"></a> [ai\_search\_name](#input\_ai\_search\_name)

Description: Name of the AI Search service

Type: `string`

### <a name="input_cosmos_db_id"></a> [cosmos\_db\_id](#input\_cosmos\_db\_id)

Description: Resource ID of the Cosmos DB account

Type: `string`

### <a name="input_cosmos_db_name"></a> [cosmos\_db\_name](#input\_cosmos\_db\_name)

Description: Name of the Cosmos DB account

Type: `string`

### <a name="input_deploy_ai_search"></a> [deploy\_ai\_search](#input\_deploy\_ai\_search)

Description: Whether AI Search is being deployed (not BYO)

Type: `bool`

### <a name="input_deploy_cosmos_db"></a> [deploy\_cosmos\_db](#input\_deploy\_cosmos\_db)

Description: Whether Cosmos DB is being deployed (not BYO)

Type: `bool`

### <a name="input_deploy_storage_account"></a> [deploy\_storage\_account](#input\_deploy\_storage\_account)

Description: Whether Storage Account is being deployed (not BYO)

Type: `bool`

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region for deployment

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: Name of the resource group

Type: `string`

### <a name="input_storage_account_id"></a> [storage\_account\_id](#input\_storage\_account\_id)

Description: Resource ID of the Storage Account

Type: `string`

### <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name)

Description: Name of the Storage Account

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_agent_subnet_resource_id"></a> [agent\_subnet\_resource\_id](#input\_agent\_subnet\_resource\_id)

Description: Subnet resource ID for the AI agent service

Type: `string`

Default: `null`

### <a name="input_create_ai_agent_service"></a> [create\_ai\_agent\_service](#input\_create\_ai\_agent\_service)

Description: Whether to create the AI agent service

Type: `bool`

Default: `true`

### <a name="input_create_ai_foundry_project"></a> [create\_ai\_foundry\_project](#input\_create\_ai\_foundry\_project)

Description: Whether to create the AI Foundry project

Type: `bool`

Default: `true`

### <a name="input_storage_connections"></a> [storage\_connections](#input\_storage\_connections)

Description: Storage connections for the agent service

Type: `list(string)`

Default: `[]`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Tags to apply to resources

Type: `map(string)`

Default: `{}`

### <a name="input_thread_storage_connections"></a> [thread\_storage\_connections](#input\_thread\_storage\_connections)

Description: Thread storage connections for the agent service

Type: `list(string)`

Default: `[]`

### <a name="input_vector_store_connections"></a> [vector\_store\_connections](#input\_vector\_store\_connections)

Description: Vector store connections for the agent service

Type: `list(string)`

Default: `[]`

## Outputs

The following outputs are exported:

### <a name="output_ai_agent_capability_host_id"></a> [ai\_agent\_capability\_host\_id](#output\_ai\_agent\_capability\_host\_id)

Description: Resource ID of the AI agent capability host

### <a name="output_ai_foundry_project_id"></a> [ai\_foundry\_project\_id](#output\_ai\_foundry\_project\_id)

Description: Resource ID of the AI Foundry project

### <a name="output_ai_foundry_project_name"></a> [ai\_foundry\_project\_name](#output\_ai\_foundry\_project\_name)

Description: Name of the AI Foundry project

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->