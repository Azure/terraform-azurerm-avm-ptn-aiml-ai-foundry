<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
terraform {
  required_version = "~> 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.2"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Application Insights for AI Foundry (required)
resource "azurerm_application_insights" "this" {
  application_type    = "web"
  location            = azurerm_resource_group.this.location
  name                = module.naming.application_insights.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

# This is the module call for AI Foundry Pattern - Basic Configuration
# Basic only deploys AI Services - no Storage, Key Vault, Cosmos DB, AI Search, Container Registry, or Networking
module "ai_foundry" {
  source = "../../"

  location = azurerm_resource_group.this.location
  name     = "ai-foundry-basic"
  # Basic AI model deployment (single model)
  ai_model_deployments = {
    "gpt-35-turbo" = {
      name = "gpt-35-turbo"
      model = {
        format  = "OpenAI"
        name    = "gpt-35-turbo"
        version = "0613"
      }
      scale = {
        type = "Standard"
      }
    }
  }
  # No agent service in basic (requires storage/other dependencies)
  create_ai_agent_service   = false
  create_ai_foundry_project = true
  # Enable telemetry for the module
  enable_telemetry               = var.enable_telemetry
  existing_ai_search_resource_id = "skip-deployment" # Skip AI search deployment
  existing_cosmos_db_resource_id = "skip-deployment" # Skip cosmos db deployment
  existing_key_vault_resource_id = "skip-deployment" # Skip key vault deployment
  existing_resource_group_name   = azurerm_resource_group.this.name
  # Basic deployment - no additional resources
  # Skip deployment by providing non-null values (these won't be used, just prevent deployment)
  existing_storage_account_resource_id = "skip-deployment" # Skip storage deployment
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.21)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_application_insights.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) (resource)
- [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

The following outputs are exported:

### <a name="output_ai_foundry_hub"></a> [ai\_foundry\_hub](#output\_ai\_foundry\_hub)

Description: DEPRECATED: AI Foundry Hub is no longer created.

### <a name="output_ai_foundry_project"></a> [ai\_foundry\_project](#output\_ai\_foundry\_project)

Description: The AI Foundry Project information.

### <a name="output_ai_search"></a> [ai\_search](#output\_ai\_search)

Description: The AI Search service information.

### <a name="output_ai_services"></a> [ai\_services](#output\_ai\_services)

Description: The AI Services account information.

### <a name="output_cosmos_db"></a> [cosmos\_db](#output\_cosmos\_db)

Description: The Cosmos DB account information.

### <a name="output_key_vault"></a> [key\_vault](#output\_key\_vault)

Description: The Key Vault information.

### <a name="output_resource_group"></a> [resource\_group](#output\_resource\_group)

Description: The resource group information.

### <a name="output_storage_account"></a> [storage\_account](#output\_storage\_account)

Description: The storage account information.

## Modules

The following Modules are called:

### <a name="module_ai_foundry"></a> [ai\_foundry](#module\_ai\_foundry)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.4.2

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: 0.5.2

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->