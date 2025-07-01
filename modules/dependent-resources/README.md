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

### <a name="input_deploy_ai_search"></a> [deploy\_ai\_search](#input\_deploy\_ai\_search)

Description: Whether to deploy AI search

Type: `bool`

### <a name="input_deploy_cosmos_db"></a> [deploy\_cosmos\_db](#input\_deploy\_cosmos\_db)

Description: Whether to deploy cosmos DB

Type: `bool`

### <a name="input_deploy_key_vault"></a> [deploy\_key\_vault](#input\_deploy\_key\_vault)

Description: Whether to deploy key vault

Type: `bool`

### <a name="input_deploy_storage_account"></a> [deploy\_storage\_account](#input\_deploy\_storage\_account)

Description: Whether to deploy storage account

Type: `bool`

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

### <a name="input_ai_search_private_endpoints"></a> [ai\_search\_private\_endpoints](#input\_ai\_search\_private\_endpoints)

Description: Private endpoint configuration for AI search

Type:

```hcl
map(object({
    name                            = optional(string, null)
    subnet_resource_id              = string
    subresource_name                = string
    private_dns_zone_resource_ids   = optional(set(string), [])
    private_dns_zone_group_name     = optional(string, "default")
    private_service_connection_name = optional(string, null)
    network_interface_name          = optional(string, null)
    location                        = optional(string, null)
    resource_group_name             = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
    tags = optional(map(string), null)
  }))
```

Default: `{}`

### <a name="input_cosmos_db_private_endpoints"></a> [cosmos\_db\_private\_endpoints](#input\_cosmos\_db\_private\_endpoints)

Description: Private endpoint configuration for cosmos DB

Type:

```hcl
map(object({
    name                            = optional(string, null)
    subnet_resource_id              = string
    subresource_name                = string
    private_dns_zone_resource_ids   = optional(set(string), [])
    private_dns_zone_group_name     = optional(string, "default")
    private_service_connection_name = optional(string, null)
    network_interface_name          = optional(string, null)
    location                        = optional(string, null)
    resource_group_name             = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
    tags = optional(map(string), null)
  }))
```

Default: `{}`

### <a name="input_key_vault_private_endpoints"></a> [key\_vault\_private\_endpoints](#input\_key\_vault\_private\_endpoints)

Description: Private endpoint configuration for key vault

Type:

```hcl
map(object({
    name                            = optional(string, null)
    subnet_resource_id              = string
    subresource_name                = string
    private_dns_zone_resource_ids   = optional(set(string), [])
    private_dns_zone_group_name     = optional(string, "default")
    private_service_connection_name = optional(string, null)
    network_interface_name          = optional(string, null)
    location                        = optional(string, null)
    resource_group_name             = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
    tags = optional(map(string), null)
  }))
```

Default: `{}`

### <a name="input_storage_private_endpoints"></a> [storage\_private\_endpoints](#input\_storage\_private\_endpoints)

Description: Private endpoint configuration for storage account

Type:

```hcl
map(object({
    name                            = optional(string, null)
    subnet_resource_id              = string
    subresource_name                = string
    private_dns_zone_resource_ids   = optional(set(string), [])
    private_dns_zone_group_name     = optional(string, "default")
    private_service_connection_name = optional(string, null)
    network_interface_name          = optional(string, null)
    location                        = optional(string, null)
    resource_group_name             = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
    tags = optional(map(string), null)
  }))
```

Default: `{}`

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