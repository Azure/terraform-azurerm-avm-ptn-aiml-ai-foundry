<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

## Resources

No resources.

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_ai_search_name"></a> [ai\_search\_name](#input\_ai\_search\_name)

Description: AI search name

Type: `string`

### <a name="input_cosmos_db_name"></a> [cosmos\_db\_name](#input\_cosmos\_db\_name)

Description: Cosmos DB name

Type: `string`

### <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name)

Description: Key vault name

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: Resource group name

Type: `string`

### <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name)

Description: Storage account name

Type: `string`

### <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id)

Description: Azure tenant ID

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_create_dependent_resources"></a> [create\_dependent\_resources](#input\_create\_dependent\_resources)

Description: Whether to create dependent resources like AI Search, Cosmos DB, Key Vault, and Storage Account. If set to false, these resources will not be created, and the module will only create the AI Foundry account.

Type: `bool`

Default: `false`

### <a name="input_create_private_endpoints"></a> [create\_private\_endpoints](#input\_create\_private\_endpoints)

Description: Whether to create private endpoints for AI Foundry, Cosmos DB, Key Vault, and AI Search. If set to false, private endpoints will not be created, and the resources will be accessible over public endpoints. This is useful for scenarios where private connectivity is not required or when using existing resources that do not require private endpoints.

Type: `bool`

Default: `false`

### <a name="input_private_dns_zone_resource_id_cosmosdb"></a> [private\_dns\_zone\_resource\_id\_cosmosdb](#input\_private\_dns\_zone\_resource\_id\_cosmosdb)

Description: (Optional) The resource ID of the private DNS zone for Cosmos DB.

Type: `string`

Default: `null`

### <a name="input_private_dns_zone_resource_id_keyvault"></a> [private\_dns\_zone\_resource\_id\_keyvault](#input\_private\_dns\_zone\_resource\_id\_keyvault)

Description: (Optional) The resource ID of the private DNS zone for Key Vault.

Type: `string`

Default: `null`

### <a name="input_private_dns_zone_resource_id_search"></a> [private\_dns\_zone\_resource\_id\_search](#input\_private\_dns\_zone\_resource\_id\_search)

Description: (Optional) The resource ID of the private DNS zone for AI Search.

Type: `string`

Default: `null`

### <a name="input_private_dns_zone_resource_id_storage_blob"></a> [private\_dns\_zone\_resource\_id\_storage\_blob](#input\_private\_dns\_zone\_resource\_id\_storage\_blob)

Description: (Optional) The resource ID of the private DNS zone for Storage Blob.

Type: `string`

Default: `null`

### <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id)

Description: (Optional) The subnet ID for private endpoints.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Tags to apply to resources

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_ai_search"></a> [ai\_search](#output\_ai\_search)

Description: AI Search service resource object

### <a name="output_ai_search_id"></a> [ai\_search\_id](#output\_ai\_search\_id)

Description: Resource ID of the AI Search service

### <a name="output_ai_search_name"></a> [ai\_search\_name](#output\_ai\_search\_name)

Description: Name of the AI Search service

### <a name="output_cosmos_db"></a> [cosmos\_db](#output\_cosmos\_db)

Description: Cosmos DB account resource object

### <a name="output_cosmos_db_id"></a> [cosmos\_db\_id](#output\_cosmos\_db\_id)

Description: Resource ID of the Cosmos DB account

### <a name="output_cosmos_db_name"></a> [cosmos\_db\_name](#output\_cosmos\_db\_name)

Description: Name of the Cosmos DB account

### <a name="output_key_vault"></a> [key\_vault](#output\_key\_vault)

Description: Key Vault resource object

### <a name="output_key_vault_id"></a> [key\_vault\_id](#output\_key\_vault\_id)

Description: Resource ID of the Key Vault

### <a name="output_key_vault_name"></a> [key\_vault\_name](#output\_key\_vault\_name)

Description: Name of the Key Vault

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: Resource ID of the primary resource (storage account if deployed, otherwise first available resource)

### <a name="output_storage_account"></a> [storage\_account](#output\_storage\_account)

Description: Storage account resource object

### <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id)

Description: Resource ID of the Storage Account

### <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name)

Description: Name of the Storage Account

## Modules

The following Modules are called:

### <a name="module_ai_search"></a> [ai\_search](#module\_ai\_search)

Source: Azure/avm-res-search-searchservice/azurerm

Version: 0.1.5

### <a name="module_cosmos_db"></a> [cosmos\_db](#module\_cosmos\_db)

Source: Azure/avm-res-documentdb-databaseaccount/azurerm

Version: 0.8.0

### <a name="module_key_vault"></a> [key\_vault](#module\_key\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: 0.10.0

### <a name="module_storage_account"></a> [storage\_account](#module\_storage\_account)

Source: Azure/avm-res-storage-storageaccount/azurerm

Version: 0.6.3

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->