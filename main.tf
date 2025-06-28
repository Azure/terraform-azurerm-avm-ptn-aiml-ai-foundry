# Resource Group - Always create since resource_group_name is always provided
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
  tags     = var.tags
}

# Random string for unique resource naming
resource "random_string" "resource_token" {
  length  = 5
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# Storage Account (BYO or Create New)
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.6.3"
  count   = local.deploy_storage_account ? 1 : 0

  location            = local.location
  name                = local.resource_names.storage_account
  resource_group_name = local.resource_group_name
  managed_identities = {
    system_assigned = true
  }
  private_endpoints = var.storage_private_endpoints
  tags              = var.tags

  # Configure for AI Foundry security requirements
  shared_access_key_enabled = false  # Disable shared key access for security
  public_network_access_enabled = length(var.storage_private_endpoints) == 0 ? true : false

  # Configure network rules for private endpoint scenarios
  network_rules = length(var.storage_private_endpoints) > 0 ? {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = []
    virtual_network_subnet_ids = []
  } : null
}

# Key Vault (BYO or Create New)
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.10.0"
  count   = local.deploy_key_vault ? 1 : 0

  location            = local.location
  name                = local.resource_names.key_vault
  resource_group_name = local.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  private_endpoints   = var.key_vault_private_endpoints
  tags                = var.tags
}

# Cosmos DB (BYO or Create New)
module "cosmos_db" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "~> 0.8.0"
  count   = local.deploy_cosmos_db ? 1 : 0

  location            = local.location
  name                = local.resource_names.cosmos_db
  resource_group_name = local.resource_group_name
  private_endpoints   = var.cosmos_db_private_endpoints
  tags                = var.tags
}

# AI Search (BYO or Create New)
module "ai_search" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "~> 0.1.5"
  count   = local.deploy_ai_search ? 1 : 0

  location            = local.location
  name                = local.resource_names.ai_search
  resource_group_name = local.resource_group_name
  private_endpoints   = var.ai_search_private_endpoints
  tags                = var.tags
}

# Azure AI Services (Using AzAPI - AIServices kind includes OpenAI)
resource "azapi_resource" "ai_services" {
  location  = local.location
  name      = local.resource_names.ai_services
  parent_id = local.resource_group_id
  type      = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      publicNetworkAccess    = length(var.ai_services_private_endpoints) == 0 ? "Enabled" : "Disabled"
      allowProjectManagement = true
      customSubDomainName    = local.resource_names.ai_services
    }
  }
  tags = var.tags

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_resource_group.this
  ]
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

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = local.resource_group_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

# AI Foundry Project (Using AzAPI)
resource "azapi_resource" "ai_foundry_project" {
  count = var.create_ai_foundry_project ? 1 : 0

  location  = local.location
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

# AI Foundry Project Connection to Storage Account (when not skipped)
resource "azapi_resource" "ai_foundry_project_connection_storage" {
  count = var.create_ai_foundry_project && local.deploy_storage_account ? 1 : 0

  name      = local.resource_names.storage_account
  parent_id = azapi_resource.ai_foundry_project[0].id
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  body = {
    properties = {
      category = "AzureStorageAccount"
      target   = "https://${local.resource_names.storage_account}.blob.core.windows.net/"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = module.storage_account[0].resource_id
        location   = local.location
      }
    }
  }

  depends_on = [
    azapi_resource.ai_foundry_project,
    module.storage_account
  ]
}

# AI Foundry Project Connection to Cosmos DB (when not skipped)
resource "azapi_resource" "ai_foundry_project_connection_cosmos" {
  count = var.create_ai_foundry_project && local.deploy_cosmos_db ? 1 : 0

  name      = local.resource_names.cosmos_db
  parent_id = azapi_resource.ai_foundry_project[0].id
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  body = {
    properties = {
      category = "CosmosDB"
      target   = "https://${local.resource_names.cosmos_db}.documents.azure.com:443/"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = module.cosmos_db[0].resource_id
        location   = local.location
      }
    }
  }

  depends_on = [
    azapi_resource.ai_foundry_project,
    module.cosmos_db
  ]
}

# AI Foundry Project Connection to AI Search (when not skipped)
resource "azapi_resource" "ai_foundry_project_connection_search" {
  count = var.create_ai_foundry_project && local.deploy_ai_search ? 1 : 0

  name      = local.resource_names.ai_search
  parent_id = azapi_resource.ai_foundry_project[0].id
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  body = {
    properties = {
      category = "CognitiveSearch"
      target   = "https://${local.resource_names.ai_search}.search.windows.net"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = module.ai_search[0].resource_id
        location   = local.location
      }
    }
  }

  depends_on = [
    azapi_resource.ai_foundry_project,
    module.ai_search
  ]
}

# AI Agent Service (Using AzAPI)
resource "azapi_resource" "ai_agent_capability_host" {
  count = var.create_ai_agent_service ? 1 : 0

  name      = local.resource_names.ai_agent_host
  parent_id = azapi_resource.ai_foundry_project[0].id
  type      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  body = {
    properties = {
      capabilityHostKind = "Agents"
      description        = "AI Agent capability host for ${var.name}"

      # Storage connections for agent service data - use connection names
      storageConnections = var.existing_storage_account_resource_id != null && var.existing_storage_account_resource_id != "skip-deployment" ? [
        var.existing_storage_account_resource_id
        ] : local.deploy_storage_account ? [
        local.resource_names.storage_account
      ] : []

      # AI Services connections for model access
      aiServicesConnections = [
        azapi_resource.ai_services.id
      ]

      # Thread storage connections - use connection names
      threadStorageConnections = var.existing_storage_account_resource_id != null && var.existing_storage_account_resource_id != "skip-deployment" ? [
        var.existing_storage_account_resource_id
        ] : local.deploy_storage_account ? [
        local.resource_names.storage_account
      ] : []

      # Vector store connections - use connection names
      vectorStoreConnections = var.existing_ai_search_resource_id != null && var.existing_ai_search_resource_id != "skip-deployment" ? [
        var.existing_ai_search_resource_id
        ] : local.deploy_ai_search ? [
        local.resource_names.ai_search
      ] : []

      # Customer subnet for private networking - use external subnet
      customerSubnet = var.agent_subnet_resource_id
    }
  }

  depends_on = [
    azapi_resource.ai_foundry_project,
    azapi_resource.ai_foundry_project_connection_storage,
    azapi_resource.ai_foundry_project_connection_cosmos,
    azapi_resource.ai_foundry_project_connection_search
  ]
}

# Private Endpoints for AI Foundry Project (via AI Services)
resource "azurerm_private_endpoint" "ai_foundry_project" {
  for_each = var.create_ai_foundry_project ? var.ai_foundry_project_private_endpoints : {}

  location            = each.value.location != null ? each.value.location : var.location
  name                = each.value.name != null ? each.value.name : "pe-${azapi_resource.ai_foundry_project[0].name}-${each.key}"
  resource_group_name = each.value.resource_group_name != null ? each.value.resource_group_name : local.resource_group_name
  subnet_id           = each.value.subnet_resource_id
  tags                = merge(var.tags, each.value.tags)

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "psc-${azapi_resource.ai_foundry_project[0].name}-${each.key}"
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
  resource_group_name = each.value.resource_group_name != null ? each.value.resource_group_name : local.resource_group_name
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
