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

# Application Insights for AI Foundry (required)
resource "azurerm_application_insights" "this" {
  name                = "${module.naming.application_insights.name_unique}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  application_type    = "web"
}

# Log Analytics Workspace for Container App Environment
resource "azurerm_log_analytics_workspace" "this" {
  name                = "${module.naming.log_analytics_workspace.name_unique}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Local values for common configuration
locals {
  tags = {
    Environment = "Demo"
    Project     = "AI-Foundry"
    CreatedBy   = "Terraform-AVM"
    Example     = "StandardPublic"
  }
}

# This is the module call for AI Foundry Pattern - Standard Public Configuration
module "ai_foundry" {
  source = "../../"

  name                = "ai-foundry-std-pub"
  location           = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  # Enable telemetry for the module
  enable_telemetry = var.enable_telemetry

  # Application Insights and Log Analytics for AI Foundry workspaces
  application_insights_id      = azurerm_application_insights.this.id
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.this.id

  # Standard OpenAI deployments
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

  # AI Foundry project configuration (standard)
  create_ai_foundry_project       = true
  ai_foundry_project_name        = "AI-Foundry-Standard-Public"
  ai_foundry_project_description = "Standard AI Foundry project with agent services (public endpoints)"

  # Enable AI agent service with public endpoints
  create_ai_agent_service = true
  ai_agent_container_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  ai_agent_cpu = 1.0
  ai_agent_memory = "2Gi"
  ai_agent_external_ingress = true
  ai_agent_target_port = 80
  ai_agent_environment_variables = {
    "ENVIRONMENT" = "STANDARD_PUBLIC"
    "LOG_LEVEL" = "INFO"
  }

  # Tags for all resources
  tags = local.tags
}
