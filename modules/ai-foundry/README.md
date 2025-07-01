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

- [azapi_resource.ai_foundry](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.ai_model_deployment](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_private_endpoint.ai_foundry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_ai_foundry_name"></a> [ai\_foundry\_name](#input\_ai\_foundry\_name)

Description: Name of the AI Foundry account

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region for deployment

Type: `string`

### <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id)

Description: Resource group ID for the AI Foundry account

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: Name of the resource group

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_ai_model_deployments"></a> [ai\_model\_deployments](#input\_ai\_model\_deployments)

Description: AI model deployments to create

Type:

```hcl
map(object({
    name = string
    model = object({
      format  = string
      name    = string
      version = string
    })
    rai_policy_name = optional(string)
    scale = object({
      type     = string
      capacity = optional(number, 1)
    })
    version_upgrade_option = optional(string)
  }))
```

Default: `{}`

### <a name="input_private_dns_zone_resource_id_ai_foundry"></a> [private\_dns\_zone\_resource\_id\_ai\_foundry](#input\_private\_dns\_zone\_resource\_id\_ai\_foundry)

Description: (Optional) The resource ID of the private DNS zone for Ai Foundry.

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

### <a name="output_ai_foundry_id"></a> [ai\_foundry\_id](#output\_ai\_foundry\_id)

Description: Resource ID of the AI Foundry account

### <a name="output_ai_foundry_name"></a> [ai\_foundry\_name](#output\_ai\_foundry\_name)

Description: Name of the AI Foundry account

### <a name="output_ai_model_deployment_ids"></a> [ai\_model\_deployment\_ids](#output\_ai\_model\_deployment\_ids)

Description: Resource IDs of the AI model deployments

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: Resource ID of the primary AI Foundry account

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->