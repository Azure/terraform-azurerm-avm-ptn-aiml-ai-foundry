# Storage Account (BYO or Create New)
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.3"
  count   = var.existing_storage_account_resource_id == null ? 1 : 0

  location            = var.location
  name                = local.resource_names.storage_account
  resource_group_name = var.resource_group_name
  private_endpoints   = var.storage_private_endpoints
  tags                = var.tags

  diagnostic_settings_storage_account = {
    workspace_resource_id = var.existing_log_analytics_workspace_resource_id != null ? {
      "default" = {
        name                                = "diag"
        log_analytics_workspace_resource_id = var.existing_log_analytics_workspace_resource_id
        log_categories                      = ["audit", "alllogs"]
      }
    } : {}
  }
}

# Key Vault (BYO or Create New)
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"
  count   = var.existing_key_vault_resource_id == null ? 1 : 0

  location            = var.location
  name                = local.resource_names.key_vault
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  private_endpoints   = var.key_vault_private_endpoints
  tags                = var.tags

  diagnostic_settings = {
    workspace_resource_id = var.existing_log_analytics_workspace_resource_id != null ? {
      "default" = {
        name                                = "diag"
        log_analytics_workspace_resource_id = var.existing_log_analytics_workspace_resource_id
        log_categories                      = ["audit", "alllogs"]
      }
    } : {}
  }
}

# Cosmos DB (BYO or Create New)
module "cosmos_db" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.8.0"
  count   = var.existing_cosmos_db_resource_id == null ? 1 : 0

  location            = var.location
  name                = local.resource_names.cosmos_db
  resource_group_name = var.resource_group_name
  private_endpoints   = var.cosmos_db_private_endpoints
  tags                = var.tags

  # Optional Log Analytics Workspace for diagnostic settings
  diagnostic_settings = {
    workspace_resource_id = var.existing_log_analytics_workspace_resource_id != null ? {
      "default" = {
        name                                = "diag"
        log_analytics_workspace_resource_id = var.existing_log_analytics_workspace_resource_id
        log_categories                      = ["audit", "alllogs"]
      }
    } : {}
  }
}

# AI Search (BYO or Create New)
module "ai_search" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.1.5"
  count   = var.existing_ai_search_resource_id == null ? 1 : 0

  location            = var.location
  name                = local.resource_names.ai_search
  resource_group_name = var.resource_group_name
  private_endpoints   = var.ai_search_private_endpoints
  tags                = var.tags

  # Optional Log Analytics Workspace for diagnostic settings
  diagnostic_settings = {
    workspace_resource_id = var.existing_log_analytics_workspace_resource_id != null ? {
      "default" = {
        name                                = "diag"
        log_analytics_workspace_resource_id = var.existing_log_analytics_workspace_resource_id
        log_categories                      = ["audit", "alllogs"]
      }
    } : {}
  }
}

# Azure AI Services (Using AzAPI - AIServices kind includes OpenAI)
resource "azapi_resource" "ai_services" {
  location  = var.location
  name      = local.resource_names.ai_services
  parent_id = local.resource_group_id
  type      = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      publicNetworkAccess = length(var.ai_services_private_endpoints) == 0 ? "Enabled" : "Disabled"
    }
  }
  tags = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# AI Model Deployments (Using AzAPI)
resource "azapi_resource" "ai_model_deployment" {
  for_each = var.ai_model_deployments

  name      = each.value.name
  parent_id = azapi_resource.ai_services.id
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-04-01-preview"
  body = {
    properties = {
      model = {
        format  = each.value.model.format
        name    = each.value.model.name
        version = each.value.model.version
      }
      raiPolicyName        = each.value.rai_policy_name
      versionUpgradeOption = each.value.version_upgrade_option
    }
    sku = {
      name     = each.value.scale.type
      capacity = each.value.scale.capacity
    }
  }

  depends_on = [
    azapi_resource.ai_services
  ]
}

# Required AVM interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = local.resource_group_id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

# AI Foundry Project (Using AzAPI) - Always created
resource "azapi_resource" "ai_foundry_project" {
  location  = var.location
  name      = local.resource_names.ai_foundry_project
  parent_id = azapi_resource.ai_services.id
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  body = {
    properties = {
      displayName = var.ai_foundry_project_display_name != null ? var.ai_foundry_project_display_name : "AI Foundry Project for ${var.name}"
      description = var.ai_foundry_project_description != null ? var.ai_foundry_project_description : "AI Foundry project for agent services and AI workloads"
    }
  }
  tags = var.tags

  # Optional identity block for managed identity support
  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azapi_resource.ai_services,
    module.storage_account,
    module.key_vault
  ]
}

# AI Agent Service (Using AzAPI) - Deploy based on configuration
resource "azapi_resource" "ai_agent_capability_host" {
  count = local.deploy_ai_agent_service ? 1 : 0

  name      = local.resource_names.ai_agent_host
  parent_id = azapi_resource.ai_foundry_project.id
  type      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  body = jsonencode({
    properties = merge({
      capabilityHostKind = "Agents"
      description        = "AI Agent capability host for ${var.name}"

      # Storage connections for agent service data
      storageConnections = var.existing_storage_account_resource_id != null ? [
        var.existing_storage_account_resource_id
        ] : [
        module.storage_account[0].resource_id
      ]

      # AI Services connections for model access
      aiServicesConnections = [
        azapi_resource.ai_services.id
      ]

      # Optional: Thread storage connections
      threadStorageConnections = var.existing_storage_account_resource_id != null ? [
        var.existing_storage_account_resource_id
        ] : [
        module.storage_account[0].resource_id
      ]

      # Optional: Vector store connections (if AI Search is available)
      vectorStoreConnections = var.existing_ai_search_resource_id != null ? [
        var.existing_ai_search_resource_id
        ] : (
        length(module.ai_search) > 0 ? [module.ai_search[0].resource_id] : []
      )
      }, var.agent_subnet_resource_id != null ? {
      # Customer subnet for private networking - only set when provided
      customerSubnet = var.agent_subnet_resource_id
    } : {})
  })

  depends_on = [
    azapi_resource.ai_foundry_project
  ]
}

# Private Endpoints for AI Foundry Project (via AI Services)
resource "azurerm_private_endpoint" "ai_foundry_project" {
  for_each = var.ai_foundry_project_private_endpoints

  location            = each.value.location != null ? each.value.location : var.location
  name                = each.value.name != null ? each.value.name : "pe-${azapi_resource.ai_foundry_project.name}-${each.key}"
  resource_group_name = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id           = each.value.subnet_resource_id
  tags                = merge(var.tags, each.value.tags)

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "psc-${azapi_resource.ai_foundry_project.name}-${each.key}"
    private_connection_resource_id = azapi_resource.ai_services.id # Connect to the AI Services account
    subresource_names              = [each.value.subresource_name]
  }
  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? [each.value.private_dns_zone_group_name] : []

    content {
      name                 = private_dns_zone_group.value
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }
}

# Private Endpoints for AI Services
resource "azurerm_private_endpoint" "ai_services" {
  for_each = var.ai_services_private_endpoints

  location            = each.value.location != null ? each.value.location : var.location
  name                = each.value.name != null ? each.value.name : "pe-${azapi_resource.ai_services.name}-${each.key}"
  resource_group_name = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id           = each.value.subnet_resource_id
  tags                = merge(var.tags, each.value.tags)

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "psc-${azapi_resource.ai_services.name}-${each.key}"
    private_connection_resource_id = azapi_resource.ai_services.id
    subresource_names              = [each.value.subresource_name]
  }
  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? [each.value.private_dns_zone_group_name] : []

    content {
      name                 = private_dns_zone_group.value
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }

  depends_on = [
    azapi_resource.ai_services
  ]
}
