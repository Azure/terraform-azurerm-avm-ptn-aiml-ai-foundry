# Resource Group - AI Foundry Project container
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
  tags     = var.tags
}

# ========================================
# Storage Account (BYO or Create New)
# ========================================
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.6.3"
  count   = var.existing_storage_account_resource_id == null ? 1 : 0

  location            = var.location
  name                = "${var.name}sa${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  managed_identities = {
    system_assigned = true
  }
  private_endpoints = var.storage_private_endpoints
  tags              = var.tags
}

# ========================================
# Key Vault (BYO or Create New)
# ========================================
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.10.0"
  count   = var.existing_key_vault_resource_id == null ? 1 : 0

  location            = var.location
  name                = "${var.name}-kv-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  private_endpoints   = var.key_vault_private_endpoints
  tags                = var.tags
}

# ========================================
# Cosmos DB (BYO or Create New)
# ========================================
module "cosmos_db" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "~> 0.8.0"
  count   = var.existing_cosmos_db_resource_id == null ? 1 : 0

  location            = var.location
  name                = "${var.name}-cosmos-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  private_endpoints   = var.cosmos_db_private_endpoints
  tags                = var.tags
}

# ========================================
# AI Search (BYO or Create New)
# ========================================
module "ai_search" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "~> 0.1.5"
  count   = var.existing_ai_search_resource_id == null ? 1 : 0

  location            = var.location
  name                = "${var.name}-search-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  private_endpoints   = var.ai_search_private_endpoints
  tags                = var.tags
}

# ========================================
# Azure AI Services (AIServices kind includes OpenAI)
# ========================================
module "ai_services" {
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "~> 0.7.1"

  kind                = "AIServices"
  location            = var.location
  name                = "${var.name}-aiservices-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "S0"
  # Deploy AI models including OpenAI
  cognitive_deployments = var.ai_model_deployments
  managed_identities = {
    system_assigned = true
  }
  private_endpoints             = var.ai_services_private_endpoints
  public_network_access_enabled = length(var.ai_services_private_endpoints) == 0 ? true : false
  tags                          = var.tags
}

# ========================================
# Random suffix for unique naming
# ========================================
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ========================================
# Data sources for existing resources
# ========================================
data "azurerm_client_config" "current" {}

data "azurerm_storage_account" "existing" {
  count = var.existing_storage_account_resource_id != null ? 1 : 0

  name                = split("/", var.existing_storage_account_resource_id)[8]
  resource_group_name = split("/", var.existing_storage_account_resource_id)[4]
}

data "azurerm_key_vault" "existing" {
  count = var.existing_key_vault_resource_id != null ? 1 : 0

  name                = split("/", var.existing_key_vault_resource_id)[8]
  resource_group_name = split("/", var.existing_key_vault_resource_id)[4]
}

data "azurerm_cosmosdb_account" "existing" {
  count = var.existing_cosmos_db_resource_id != null ? 1 : 0

  name                = split("/", var.existing_cosmos_db_resource_id)[8]
  resource_group_name = split("/", var.existing_cosmos_db_resource_id)[4]
}

data "azurerm_search_service" "existing" {
  count = var.existing_ai_search_resource_id != null ? 1 : 0

  name                = split("/", var.existing_ai_search_resource_id)[8]
  resource_group_name = split("/", var.existing_ai_search_resource_id)[4]
}

# ========================================
# Required AVM interfaces
# ========================================
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_resource_group.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_resource_group.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

# ========================================
# AI Foundry Project (Using AzAPI - Microsoft.CognitiveServices/accounts/projects)
# ========================================
resource "azapi_resource" "ai_foundry_project" {
  count = var.create_ai_foundry_project ? 1 : 0

  location  = var.location
  name      = var.ai_foundry_project_name != null ? var.ai_foundry_project_name : "${var.name}-aiproject-${random_string.suffix.result}"
  parent_id = module.ai_services.resource_id
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
    module.ai_services,
    module.storage_account,
    module.key_vault
  ]
}

# ========================================
# AI Agent Service (Using AzAPI - Microsoft.CognitiveServices/accounts/projects/capabilityHosts)
# ========================================
resource "azapi_resource" "ai_agent_capability_host" {
  count = var.create_ai_agent_service ? 1 : 0

  name      = var.ai_agent_host_name != null ? var.ai_agent_host_name : "${var.name}-agent-host-${random_string.suffix.result}"
  parent_id = azapi_resource.ai_foundry_project[0].id
  type      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  body = {
    properties = {
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
        module.ai_services.resource_id
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

      # Customer subnet for private networking
      customerSubnet = var.ai_agent_subnet_resource_id

      # Optional tags within properties
      tags = var.tags
    }
  }

  depends_on = [
    azapi_resource.ai_foundry_project
  ]
}

# ========================================
# Private Endpoints for AI Foundry Project (via AI Services)
# ========================================
resource "azurerm_private_endpoint" "ai_foundry_project" {
  for_each = var.create_ai_foundry_project ? var.ai_foundry_project_private_endpoints : {}

  location            = each.value.location != null ? each.value.location : var.location
  name                = each.value.name != null ? each.value.name : "pe-${azapi_resource.ai_foundry_project[0].name}-${each.key}"
  resource_group_name = each.value.resource_group_name != null ? each.value.resource_group_name : azurerm_resource_group.this.name
  subnet_id           = each.value.subnet_resource_id
  tags                = merge(var.tags, each.value.tags)

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "psc-${azapi_resource.ai_foundry_project[0].name}-${each.key}"
    private_connection_resource_id = module.ai_services.resource_id # Connect to the AI Services account
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

# ========================================
