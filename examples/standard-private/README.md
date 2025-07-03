<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  storage_use_azuread = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.2"

  availability_zones_filter = true
  geography_filter          = "Australia"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

locals {
  base_name = "private"
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix        = [local.base_name]
  unique-length = 5
}

resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

# Virtual Network for private endpoints and agent services
resource "azurerm_virtual_network" "this" {
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
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
  address_prefixes     = ["10.0.2.0/24"]
  name                 = "snet-agent-services"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name

  # Required for Container App Environment
  delegation {
    name = "Microsoft.App.environments"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Subnet for Bastion
resource "azurerm_subnet" "bastion" {
  address_prefixes     = ["10.0.3.0/26"]
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

# Subnet for VM
resource "azurerm_subnet" "vm" {
  address_prefixes     = ["10.0.4.0/24"]
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

# Storage Account Private DNS Zone
resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  name                  = "vnet-link-storage-blob"
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

# Key Vault Private DNS Zone
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "vnet-link-keyvault"
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

# Cosmos DB Private DNS Zone
resource "azurerm_private_dns_zone" "cosmosdb" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmosdb" {
  name                  = "vnet-link-cosmosdb"
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

# AI Search Private DNS Zone
resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "search" {
  name                  = "vnet-link-search"
  private_dns_zone_name = azurerm_private_dns_zone.search.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

# Cognitive Services Private DNS Zone
resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  name                  = "vnet-link-openai"
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
}


module "bastion_host" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "0.8.0"

  location            = module.regions.regions[random_integer.region_index.result].name
  name                = module.naming.bastion_host.name_unique
  resource_group_name = azurerm_resource_group.this.name
  copy_paste_enabled  = true
  file_copy_enabled   = true
  ip_configuration = {
    name             = "IpConf"
    subnet_id        = azurerm_subnet.bastion.id
    create_public_ip = true
  }
  ip_connect_enabled     = true
  scale_units            = 2
  shareable_link_enabled = true
  sku                    = "Standard"
  tunneling_enabled      = true
}

module "virtual_machine" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.19.3"

  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.virtual_machine.name_unique
  network_interfaces = {
    network_interface_1 = {
      name = "${module.naming.network_interface.name_unique}-vm"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "internal"
          private_ip_subnet_resource_id = azurerm_subnet.vm.id
        }
      }
    }
  }
  resource_group_name                                    = azurerm_resource_group.this.name
  zone                                                   = "1"
  admin_username                                         = "azureadmin"
  bypass_platform_safety_checks_on_user_schedule_enabled = false
  disable_password_authentication                        = false
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  patch_assessment_mode = "AutomaticByPlatform"
  patch_mode            = "AutomaticByPlatform"
  sku_size              = "Standard_D4s_v3"
  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }
}

# This is the module call for AI Foundry Pattern - Standard Private Configuration
module "ai_foundry" {
  source = "../../"

  base_name = local.base_name
  location  = azurerm_resource_group.this.location
  ai_model_deployments = {
    "gpt-4o" = {
      name = "gpt-4.1"
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1"
        version = "2025-04-14"
      }
      scale = {
        type     = "GlobalStandard"
        capacity = 1
      }
    }
  }
  create_ai_agent_service                   = false # default: false
  create_dependent_resources                = true  # default: false
  create_private_endpoints                  = true  # default: false
  create_project_connections                = true  # default: false
  create_resource_group                     = false # default: false
  private_dns_zone_resource_id_ai_foundry   = azurerm_private_dns_zone.openai.id
  private_dns_zone_resource_id_cosmosdb     = azurerm_private_dns_zone.cosmosdb.id
  private_dns_zone_resource_id_keyvault     = azurerm_private_dns_zone.keyvault.id
  private_dns_zone_resource_id_search       = azurerm_private_dns_zone.search.id
  private_dns_zone_resource_id_storage_blob = azurerm_private_dns_zone.storage_blob.id
  private_endpoint_subnet_id                = azurerm_subnet.private_endpoints.id
  resource_group_name                       = azurerm_resource_group.this.name
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_private_dns_zone.cosmosdb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone.keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone.openai](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone.search](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone.storage_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone_virtual_network_link.cosmosdb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_private_dns_zone_virtual_network_link.keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_private_dns_zone_virtual_network_link.openai](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_private_dns_zone_virtual_network_link.search](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_private_dns_zone_virtual_network_link.storage_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.agent_services](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.bastion](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.private_endpoints](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_ai_foundry"></a> [ai\_foundry](#module\_ai\_foundry)

Source: ../../

Version:

### <a name="module_bastion_host"></a> [bastion\_host](#module\_bastion\_host)

Source: Azure/avm-res-network-bastionhost/azurerm

Version: 0.8.0

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.4.2

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: 0.5.2

### <a name="module_virtual_machine"></a> [virtual\_machine](#module\_virtual\_machine)

Source: Azure/avm-res-compute-virtualmachine/azurerm

Version: 0.19.3

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->