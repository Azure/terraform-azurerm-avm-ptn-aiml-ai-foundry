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

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

# ========================================
# Basic Networking Infrastructure
# ========================================

# Virtual Network for basic deployment (optional for basic, but good practice)
resource "azurerm_virtual_network" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}

# Subnet for private endpoints (even in basic, good to have for future expansion)
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

# Local values for common configuration
locals {
  tags = {
    Environment = "Demo"
    Project     = "AI-Foundry"
    CreatedBy   = "Terraform-AVM"
    Example     = "Basic"
  }
}

# This is the module call for AI Foundry Pattern - Basic Configuration
module "ai_foundry" {
  source = "../../"

  location                             = azurerm_resource_group.this.location
  name                                 = "ai-foundry-basic"
  ai_foundry_project_private_endpoints = {}
  # Basic AI model deployments
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
  ai_search_private_endpoints   = {}
  ai_services_private_endpoints = {}
  cosmos_db_private_endpoints   = {}
  # Enable agent service in basic configuration (with public endpoints)
  create_ai_agent_service = true
  # Create AI Foundry project with basic configuration
  create_ai_foundry_project = true
  # Enable telemetry for the module
  enable_telemetry                    = var.enable_telemetry
  existing_application_insights_id    = azurerm_application_insights.this.id
  existing_log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  existing_resource_group_name        = azurerm_resource_group.this.name
  existing_subnet_id                  = azurerm_subnet.agent_services.id
  key_vault_private_endpoints         = {}
  # No private endpoints in basic configuration (public endpoints only)
  storage_private_endpoints = {}
  # Tags for all resources
  tags = local.tags
}
