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

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"

  availability_zones_filter = true
  geography_filter          = "Australia"
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

# Create a resource group first (to be used by AI Foundry module)
resource "azurerm_resource_group" "example" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Application Insights for AI Foundry (required)
resource "azurerm_application_insights" "this" {
  application_type    = "web"
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = module.naming.application_insights.name_unique
  resource_group_name = azurerm_resource_group.example.name
}

# Log Analytics Workspace for Container App Environment
resource "azurerm_log_analytics_workspace" "this" {
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.example.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

# ========================================
# Networking Infrastructure
# ========================================

# Virtual Network for private endpoints and agent services
resource "azurerm_virtual_network" "this" {
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet for private endpoints
resource "azurerm_subnet" "private_endpoints" {
  address_prefixes     = ["10.0.1.0/24"]
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.this.name
}

# Subnet for AI agent services (Container Apps)
resource "azurerm_subnet" "agent_services" {
  address_prefixes     = ["10.0.2.0/24"]
  name                 = "snet-agent-services"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.this.name

  # Required for Container App Environment
  delegation {
    name = "Microsoft.App.environments"

    service_delegation {
      name = "Microsoft.App/environments"
    }
  }
}

# Subnet for Bastion
resource "azurerm_subnet" "bastion" {
  address_prefixes     = ["10.0.3.0/26"]
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.this.name
}

# Subnet for VM
resource "azurerm_subnet" "vm" {
  address_prefixes     = ["10.0.4.0/24"]
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.this.name
}

# ========================================
# Private DNS Zones and VNet Links
# ========================================

# Storage Account Private DNS Zone
resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  name                  = "vnet-link-storage-blob"
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  resource_group_name   = azurerm_resource_group.example.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

# Key Vault Private DNS Zone
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "vnet-link-keyvault"
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  resource_group_name   = azurerm_resource_group.example.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

# Cosmos DB Private DNS Zone
resource "azurerm_private_dns_zone" "cosmosdb" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmosdb" {
  name                  = "vnet-link-cosmosdb"
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb.name
  resource_group_name   = azurerm_resource_group.example.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

# AI Search Private DNS Zone
resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "search" {
  name                  = "vnet-link-search"
  private_dns_zone_name = azurerm_private_dns_zone.search.name
  resource_group_name   = azurerm_resource_group.example.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

# Cognitive Services Private DNS Zone
resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  name                  = "vnet-link-openai"
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  resource_group_name   = azurerm_resource_group.example.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

# ========================================
# Bastion Host (using AVM module)
# ========================================

# Public IP for Bastion
resource "azurerm_public_ip" "bastion" {
  allocation_method   = "Static"
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = module.naming.public_ip.name_unique
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
}

module "bastion_host" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "~> 0.3"

  location            = module.regions.regions[random_integer.region_index.result].name
  name                = module.naming.bastion_host.name_unique
  resource_group_name = azurerm_resource_group.example.name
  copy_paste_enabled  = true
  file_copy_enabled   = true
  ip_configuration = {
    name                 = "IpConf"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
  ip_connect_enabled     = true
  scale_units            = 2
  shareable_link_enabled = true
  sku                    = "Standard"
  tunneling_enabled      = true
}

# ========================================
# Windows Virtual Machine (using AVM module)
# ========================================

module "virtual_machine" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "~> 0.15"

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
  resource_group_name             = azurerm_resource_group.example.name
  zone                            = "1"
  admin_password                  = "P@ssw0rd1234!"
  admin_username                  = "azureadmin"
  disable_password_authentication = false
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  sku_size = "Standard_D4s_v3"
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

  location                 = module.regions.regions[random_integer.region_index.result].name
  name                     = "std-prv"
  agent_subnet_resource_id = azurerm_subnet.agent_services.id
  ai_foundry_private_endpoints = {
    "account" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
      subresource_name   = "account"
      private_dns_zone_resource_ids = [
        azurerm_private_dns_zone.openai.id
      ]
    }
  }
  ai_foundry_project_description = "Standard AI Foundry project with agent services (private endpoints)"
  ai_foundry_project_name        = "AI-Foundry-Standard-Private"
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
  ai_search_private_endpoints = {
    "searchService" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
      subresource_name   = "searchService"
      private_dns_zone_resource_ids = [
        azurerm_private_dns_zone.search.id
      ]
    }
  }
  cosmos_db_private_endpoints = {
    "sql" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
      subresource_name   = "sql"
      private_dns_zone_resource_ids = [
        azurerm_private_dns_zone.cosmosdb.id
      ]
    }
  }
  create_ai_agent_service   = true
  create_ai_foundry_project = true
  enable_telemetry          = true
  key_vault_private_endpoints = {
    "vault" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
      subresource_name   = "vault"
      private_dns_zone_resource_ids = [
        azurerm_private_dns_zone.keyvault.id
      ]
    }
  }
  resource_group_name = azurerm_resource_group.example.name
  storage_private_endpoints = {
    "blob" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
      subresource_name   = "blob"
      private_dns_zone_resource_ids = [
        azurerm_private_dns_zone.storage_blob.id
      ]
    }
  }
}
