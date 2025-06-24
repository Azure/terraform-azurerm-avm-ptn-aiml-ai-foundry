terraform {
  required_version = "~> 1.5"
  required_providers {
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

# Local values for common configuration
locals {
  tags = {
    Environment = "Demo"
    Project     = "AI-Foundry"
    CreatedBy   = "Terraform-AVM"
  }
}

# This is the module call for AI Foundry Pattern
module "ai_foundry" {
  source = "../../"

  name                = "ai-foundry-example"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  # Enable telemetry for the module
  enable_telemetry = var.enable_telemetry

  # Configure OpenAI deployments
  openai_deployments = {
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

  storage_private_endpoints = {
    "blob" = {
      subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/private-endpoint-subnet"
      subresource_name = "blob"
      private_dns_zone_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
      ]
    }
  }

  key_vault_private_endpoints = {
    "vault" = {
      subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/private-endpoint-subnet"
      subresource_name = "vault"
      private_dns_zone_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      ]
    }
  }

  cosmos_db_private_endpoints = {
    "sql" = {
      subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/private-endpoint-subnet"
      subresource_name = "sql"
      private_dns_zone_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.documents.azure.com"
      ]
    }
  }

  ai_search_private_endpoints = {
    "searchService" = {
      subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/private-endpoint-subnet"
      subresource_name = "searchService"
      private_dns_zone_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.search.windows.net"
      ]
    }
  }

  cognitive_services_private_endpoints = {
    "account" = {
      subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/private-endpoint-subnet"
      subresource_name = "account"
      private_dns_zone_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com"
      ]
    }
  }

  # AI Foundry project configuration
  ai_foundry_project_name        = "AI-Foundry-Demo"
  ai_foundry_project_description = "Demonstration AI Foundry project with full AI services stack"

  # Tags for all resources
  tags = local.tags
}
