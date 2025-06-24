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
  count  = var.existing_storage_account_resource_id == null ? 1 : 0
  source = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.6.3"

  name                = "${var.name}sa${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location           = var.location

  managed_identities = {
    system_assigned = true
  }

  private_endpoints = var.storage_private_endpoints
  tags = var.tags
}

# ========================================
# Key Vault (BYO or Create New)
# ========================================
module "key_vault" {
  count  = var.existing_key_vault_resource_id == null ? 1 : 0
  source = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.10.0"

  name                = "${var.name}-kv-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location           = var.location
  tenant_id          = data.azurerm_client_config.current.tenant_id

  private_endpoints = var.key_vault_private_endpoints
  tags = var.tags
}

# ========================================
# Cosmos DB (BYO or Create New)
# ========================================
module "cosmos_db" {
  count  = var.existing_cosmos_db_resource_id == null ? 1 : 0
  source = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "~> 0.8.0"

  name                = "${var.name}-cosmos-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location           = var.location

  private_endpoints = var.cosmos_db_private_endpoints
  tags = var.tags
}

# ========================================
# AI Search (BYO or Create New)
# ========================================
module "ai_search" {
  count  = var.existing_ai_search_resource_id == null ? 1 : 0
  source = "Azure/avm-res-search-searchservice/azurerm"
  version = "~> 0.1.5"

  name                = "${var.name}-search-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location           = var.location

  private_endpoints = var.ai_search_private_endpoints
  tags = var.tags
}

# ========================================
# Azure OpenAI / Cognitive Services
# ========================================
module "cognitive_services" {
  source = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "~> 0.7.1"

  name                = "${var.name}-openai-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location           = var.location

  kind                         = "OpenAI"
  sku_name                    = "S0"
  public_network_access_enabled = false

  # Deploy required models for AI Foundry
  cognitive_deployments = var.openai_deployments

  managed_identities = {
    system_assigned = true
  }

  private_endpoints = var.cognitive_services_private_endpoints
  tags = var.tags
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
