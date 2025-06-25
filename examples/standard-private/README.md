<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
terraform {
  required_version = "~> 1.5"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
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
  version = "~> 0.1"
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
  version = "~> 0.3"
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

# Log Analytics Workspace for Container App Environment
resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

# ========================================
# Networking Infrastructure
# ========================================

# Virtual Network for private endpoints and agent services
resource "azurerm_virtual_network" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}

# Subnet for private endpoints
resource "azurerm_subnet" "private_endpoints" {
  address_prefixes     = ["10.0.1.0/24"]
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

# Subnet for AI agent services (Container Apps)
resource "azurerm_subnet" "agent_services" {
  address_prefixes     = ["10.0.2.0/23"]
  name                 = "snet-agent-services"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name

  # Required for Container App Environment
  delegation {
    name = "Microsoft.App.environments"

    service_delegation {
      name = "Microsoft.App/environments"
    }
  }
}

# ========================================
# Private DNS Zones and VNet Links
# ========================================

# Storage Account Private DNS Zone
resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  name                  = "vnet-link-storage-blob"
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.tags
}

# Key Vault Private DNS Zone
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "vnet-link-keyvault"
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.tags
}

# Cosmos DB Private DNS Zone
resource "azurerm_private_dns_zone" "cosmosdb" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmosdb" {
  name                  = "vnet-link-cosmosdb"
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.tags
}

# AI Search Private DNS Zone
resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "search" {
  name                  = "vnet-link-search"
  private_dns_zone_name = azurerm_private_dns_zone.search.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.tags
}

# Cognitive Services Private DNS Zone
resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  name                  = "vnet-link-openai"
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.tags
}

# Machine Learning Workspace Private DNS Zone
resource "azurerm_private_dns_zone" "ml_workspace" {
  name                = "privatelink.api.azureml.ms"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "ml_workspace" {
  name                  = "vnet-link-ml-workspace"
  private_dns_zone_name = azurerm_private_dns_zone.ml_workspace.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.tags
}

# Local values for common configuration
locals {
  tags = {
    Environment = "Demo"
    Project     = "AI-Foundry"
    CreatedBy   = "Terraform-AVM"
    Example     = "StandardPrivate"
  }
}

# This is the module call for AI Foundry Pattern - Standard Private Configuration
module "ai_foundry" {
  source = "../../"

  location                       = azurerm_resource_group.this.location
  name                           = "ai-foundry-std-prv"
  resource_group_name            = azurerm_resource_group.this.name
  ai_agent_subnet_resource_id    = azurerm_subnet.agent_services.id
  ai_foundry_project_description = "Standard AI Foundry project with agent services (private endpoints)"
  ai_foundry_project_name        = "AI-Foundry-Standard-Private"
  ai_foundry_project_private_endpoints = {
    "amlworkspace" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
      subresource_name   = "amlworkspace"
      private_dns_zone_resource_ids = [
        azurerm_private_dns_zone.ml_workspace.id
      ]
    }
  }
  # Standard AI model deployments (including OpenAI)
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
    "gpt-35-turbo" = {
      name = "gpt-35-turbo"
      model = {
        format  = "OpenAI"
        name    = "gpt-35-turbo"
        version = "0125"
      }
      scale = {
        type = "Standard"
      }
    }
    "text-embedding-3-large" = {
      name = "text-embedding-3-large"
      model = {
        format  = "OpenAI"
        name    = "text-embedding-3-large"
        version = "1"
      }
      scale = {
        type = "Standard"
      }
    }
  }
  ai_search_private_endpoints = {
    "searchService" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
      subresource_name   = "searchService"
      private_dns_zone_resource_ids = [
        azurerm_private_dns_zone.search.id
      ]
    }
  }
  ai_services_private_endpoints = {
    "account" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
      subresource_name   = "account"
      private_dns_zone_resource_ids = [
        azurerm_private_dns_zone.openai.id
      ]
    }
  }
  # Application Insights and Log Analytics for AI Foundry workspaces
  application_insights_id = azurerm_application_insights.this.id
  cosmos_db_private_endpoints = {
    "sql" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
      subresource_name   = "sql"
      private_dns_zone_resource_ids = [
        azurerm_private_dns_zone.cosmosdb.id
      ]
    }
  }
  # Enable AI agent service with dedicated subnet
  create_ai_agent_service = true
  # AI Foundry project configuration (standard with private endpoints)
  create_ai_foundry_project = true
  # Enable telemetry for the module
  enable_telemetry = var.enable_telemetry
  key_vault_private_endpoints = {
    "vault" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
      subresource_name   = "vault"
      private_dns_zone_resource_ids = [
        azurerm_private_dns_zone.keyvault.id
      ]
    }
  }
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  # Private endpoint configurations with created DNS zones
  storage_private_endpoints = {
    "blob" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
      subresource_name   = "blob"
      private_dns_zone_resource_ids = [
        azurerm_private_dns_zone.storage_blob.id
      ]
    }
  }
  # Tags for all resources
  tags = local.tags
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.21)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_application_insights.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) (resource)
- [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_private_dns_zone.cosmosdb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone.keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone.ml_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone.openai](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone.search](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone.storage_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone_virtual_network_link.cosmosdb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_private_dns_zone_virtual_network_link.keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_private_dns_zone_virtual_network_link.ml_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_private_dns_zone_virtual_network_link.openai](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_private_dns_zone_virtual_network_link.search](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_private_dns_zone_virtual_network_link.storage_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.agent_services](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.private_endpoints](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
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

### <a name="output_ai_agent_environment_id"></a> [ai\_agent\_environment\_id](#output\_ai\_agent\_environment\_id)

Description: The resource ID of the Container App Environment for AI agent services.

### <a name="output_ai_agent_service_fqdn"></a> [ai\_agent\_service\_fqdn](#output\_ai\_agent\_service\_fqdn)

Description: The FQDN of the AI agent service Container App.

### <a name="output_ai_agent_service_id"></a> [ai\_agent\_service\_id](#output\_ai\_agent\_service\_id)

Description: The resource ID of the AI agent service Container App.

### <a name="output_ai_agent_service_name"></a> [ai\_agent\_service\_name](#output\_ai\_agent\_service\_name)

Description: The name of the AI agent service Container App.

### <a name="output_ai_foundry_hub_private_endpoints"></a> [ai\_foundry\_hub\_private\_endpoints](#output\_ai\_foundry\_hub\_private\_endpoints)

Description: DEPRECATED: AI Foundry Hub is no longer created.

### <a name="output_ai_foundry_project_id"></a> [ai\_foundry\_project\_id](#output\_ai\_foundry\_project\_id)

Description: The resource ID of the AI Foundry Project.

### <a name="output_ai_foundry_project_name"></a> [ai\_foundry\_project\_name](#output\_ai\_foundry\_project\_name)

Description: The name of the AI Foundry Project.

### <a name="output_ai_foundry_project_private_endpoints"></a> [ai\_foundry\_project\_private\_endpoints](#output\_ai\_foundry\_project\_private\_endpoints)

Description: A map of private endpoints created for the AI Foundry Project.

### <a name="output_ai_foundry_project_workspace_url"></a> [ai\_foundry\_project\_workspace\_url](#output\_ai\_foundry\_project\_workspace\_url)

Description: The discovery URL of the AI Foundry Project.

### <a name="output_ai_search"></a> [ai\_search](#output\_ai\_search)

Description: The Azure AI Search service used for intelligent search capabilities.

### <a name="output_ai_services"></a> [ai\_services](#output\_ai\_services)

Description: The AI Services account used for AI capabilities.

### <a name="output_application_insights"></a> [application\_insights](#output\_application\_insights)

Description: The Application Insights instance used for monitoring.

### <a name="output_cognitive_services"></a> [cognitive\_services](#output\_cognitive\_services)

Description: The AI Services account (legacy name for backward compatibility).

### <a name="output_cosmos_db"></a> [cosmos\_db](#output\_cosmos\_db)

Description: The Cosmos DB account used for AI Foundry metadata storage.

### <a name="output_key_vault"></a> [key\_vault](#output\_key\_vault)

Description: The Key Vault used for AI Foundry secrets management.

### <a name="output_location"></a> [location](#output\_location)

Description: The Azure region where resources are deployed.

### <a name="output_private_dns_zones"></a> [private\_dns\_zones](#output\_private\_dns\_zones)

Description: The private DNS zones created for private endpoint connectivity.

### <a name="output_resource_group"></a> [resource\_group](#output\_resource\_group)

Description: The resource group containing all AI Foundry resources.

### <a name="output_storage_account"></a> [storage\_account](#output\_storage\_account)

Description: The storage account used for AI Foundry workloads.

### <a name="output_virtual_network"></a> [virtual\_network](#output\_virtual\_network)

Description: The virtual network created for private endpoint connectivity.

## Modules

The following Modules are called:

### <a name="module_ai_foundry"></a> [ai\_foundry](#module\_ai\_foundry)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: ~> 0.1

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->