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

# Log Analytics Workspace for Container App Environment and AVM modules
resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

# ========================================
# Create Prerequisite Resources (BYO Resources)
# ========================================

# Storage Account to be used as existing resource
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.3"

  location            = azurerm_resource_group.this.location
  name                = module.naming.storage_account.name_unique
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
}

# Key Vault to be used as existing resource
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  location            = azurerm_resource_group.this.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
}

# Cosmos DB Account to be used as existing resource
module "cosmos_db" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.8.0"

  location            = azurerm_resource_group.this.location
  name                = module.naming.cosmosdb_account.name_unique
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
}

# AI Search Service to be used as existing resource
module "ai_search" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.1.5"

  location            = azurerm_resource_group.this.location
  name                = module.naming.search_service.name_unique
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# ========================================
# AI Foundry Pattern with BYO Resources
# ========================================

# This is the module call for AI Foundry Pattern - BYO Resources Configuration
module "ai_foundry" {
  source = "../../"

  location                       = azurerm_resource_group.this.location
  name                           = "ai-foundry-byor"
  resource_group_name            = azurerm_resource_group.this.name
  ai_foundry_project_description = "AI Foundry project demonstrating Bring Your Own Resources (BYOR)"
  ai_foundry_project_name        = "AI-Foundry-BYOR"
  # Standard AI model deployment
  ai_model_deployments = {
    "gpt-4o" = {
      name = "gpt-4o"
      model = {
        format  = "OpenAI"
        name    = "gpt-4o"
        version = "2024-08-06"
      }
      scale = {
        type = "Standard"
      }
    }
  }
  # Enable agent service (no agent subnet required for BYOR public scenario)
  create_ai_agent_service                      = true
  enable_telemetry                             = true
  existing_ai_search_resource_id               = module.ai_search.resource_id
  existing_cosmos_db_resource_id               = module.cosmos_db.resource_id
  existing_key_vault_resource_id               = module.key_vault.resource_id
  existing_log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.this.id
  # Use existing resources created above
  existing_storage_account_resource_id = module.storage_account.resource_id
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

- [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure region where the resources will be deployed.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The name of an existing resource group to deploy resources into.

Type: `string`

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

### <a name="output_ai_foundry_project_id"></a> [ai\_foundry\_project\_id](#output\_ai\_foundry\_project\_id)

Description: The resource ID of the AI Foundry project.

### <a name="output_ai_foundry_project_name"></a> [ai\_foundry\_project\_name](#output\_ai\_foundry\_project\_name)

Description: The name of the AI Foundry project.

### <a name="output_ai_search_id"></a> [ai\_search\_id](#output\_ai\_search\_id)

Description: The resource ID of the AI Search service (BYO resource).

### <a name="output_ai_services"></a> [ai\_services](#output\_ai\_services)

Description: The AI Services account information.

### <a name="output_ai_services_endpoint"></a> [ai\_services\_endpoint](#output\_ai\_services\_endpoint)

Description: The endpoint URL of the AI Services account.

### <a name="output_cosmos_db_id"></a> [cosmos\_db\_id](#output\_cosmos\_db\_id)

Description: The resource ID of the Cosmos DB account (BYO resource).

### <a name="output_key_vault_id"></a> [key\_vault\_id](#output\_key\_vault\_id)

Description: The resource ID of the Key Vault (BYO resource).

### <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id)

Description: The resource ID of the Log Analytics Workspace.

### <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id)

Description: The resource ID of the storage account (BYO resource).

## Modules

The following Modules are called:

### <a name="module_ai_foundry"></a> [ai\_foundry](#module\_ai\_foundry)

Source: ../../

Version:

### <a name="module_ai_search"></a> [ai\_search](#module\_ai\_search)

Source: Azure/avm-res-search-searchservice/azurerm

Version: 0.1.5

### <a name="module_cosmos_db"></a> [cosmos\_db](#module\_cosmos\_db)

Source: Azure/avm-res-documentdb-databaseaccount/azurerm

Version: 0.8.0

### <a name="module_key_vault"></a> [key\_vault](#module\_key\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: 0.10.0

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.4.2

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: 0.5.2

### <a name="module_storage_account"></a> [storage\_account](#module\_storage\_account)

Source: Azure/avm-res-storage-storageaccount/azurerm

Version: 0.6.3

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->