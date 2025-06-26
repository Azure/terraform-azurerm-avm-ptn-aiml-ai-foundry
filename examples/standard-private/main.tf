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

# ========================================
# Bastion Host
# ========================================

# Public IP for Bastion
resource "azurerm_public_ip" "bastion" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.public_ip.name_unique
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# Bastion Host for secure VM access
resource "azurerm_bastion_host" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.bastion_host.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  tunneling_enabled   = true
  file_copy_enabled   = true

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = local.tags
}

# ========================================
# Virtual Machine
# ========================================

# Network Security Group for VM
resource "azurerm_network_security_group" "vm" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.network_security_group.name_unique}-vm"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

# Network Security Rule to allow internal traffic
resource "azurerm_network_security_rule" "allow_internal" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "AllowInternal"
  network_security_group_name = azurerm_network_security_group.vm.name
  priority                    = 1000
  protocol                    = "*"
  resource_group_name         = azurerm_resource_group.this.name
  source_address_prefix       = "10.0.0.0/16"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
}

# Associate NSG with VM subnet
resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# Network Interface for VM
resource "azurerm_network_interface" "vm" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.network_interface.name_unique}-vm"
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.tags
}

# Virtual Machine for AI development and testing
resource "azurerm_linux_virtual_machine" "this" {
  location              = azurerm_resource_group.this.location
  name                  = module.naming.virtual_machine.name_unique
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_D4s_v3"
  admin_username        = "adminuser"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.vm_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = local.tags
}

# SSH Key for VM access
resource "tls_private_key" "vm_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
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
  # Application Insights and Log Analytics for AI Foundry workspaces
  existing_application_insights_id    = azurerm_application_insights.this.id
  existing_log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  existing_resource_group_name        = azurerm_resource_group.this.name
  existing_subnet_id                  = azurerm_subnet.agent_services.id
  key_vault_private_endpoints = {
    "vault" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
      subresource_name   = "vault"
      private_dns_zone_resource_ids = [
        azurerm_private_dns_zone.keyvault.id
      ]
    }
  }
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
