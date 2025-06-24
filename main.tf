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

# ========================================
# AI Foundry Hub (Machine Learning Workspace)
# ========================================
resource "azurerm_machine_learning_workspace" "ai_foundry_hub" {
  name                          = "${var.name}-aihub-${random_string.suffix.result}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.this.name
  application_insights_id       = var.application_insights_id
  key_vault_id                  = var.existing_key_vault_resource_id != null ? var.existing_key_vault_resource_id : module.key_vault[0].resource_id
  storage_account_id            = var.existing_storage_account_resource_id != null ? var.existing_storage_account_resource_id : module.storage_account[0].resource_id

  # Use default kind (will be configured as Hub via additional settings)
  description = "AI Foundry Hub for agent services and AI workloads"

  identity {
    type = "SystemAssigned"
  }

  # Enable public network access based on whether private endpoints are configured
  public_network_access_enabled = length(var.ai_foundry_hub_private_endpoints) == 0 ? true : false

  tags = var.tags
}

# ========================================
# AI Foundry Project (Machine Learning Workspace)
# ========================================
resource "azurerm_machine_learning_workspace" "ai_foundry_project" {
  count = var.create_ai_foundry_project ? 1 : 0

  name                          = var.ai_foundry_project_name != null ? var.ai_foundry_project_name : "${var.name}-aiproject-${random_string.suffix.result}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.this.name
  application_insights_id       = var.application_insights_id
  key_vault_id                  = var.existing_key_vault_resource_id != null ? var.existing_key_vault_resource_id : module.key_vault[0].resource_id
  storage_account_id            = var.existing_storage_account_resource_id != null ? var.existing_storage_account_resource_id : module.storage_account[0].resource_id

  # Configure as project workspace
  description = var.ai_foundry_project_description

  identity {
    type = "SystemAssigned"
  }

  # Enable public network access based on whether private endpoints are configured
  public_network_access_enabled = length(var.ai_foundry_project_private_endpoints) == 0 ? true : false

  tags = var.tags
}

# ========================================
# AI Foundry Agent Service (Container App)
# ========================================
resource "azurerm_container_app_environment" "ai_agent_env" {
  count = var.create_ai_agent_service ? 1 : 0

  name                       = "${var.name}-agent-env-${random_string.suffix.result}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Use agent subnet if provided, otherwise use default subnet
  infrastructure_subnet_id = var.ai_agent_subnet_resource_id
  internal_load_balancer_enabled = var.ai_agent_subnet_resource_id != null ? true : false

  tags = var.tags
}

resource "azurerm_container_app" "ai_agent_service" {
  count = var.create_ai_agent_service ? 1 : 0

  name                         = "${var.name}-agent-${random_string.suffix.result}"
  container_app_environment_id = azurerm_container_app_environment.ai_agent_env[0].id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = "ai-agent"
      image  = var.ai_agent_container_image
      cpu    = var.ai_agent_cpu
      memory = var.ai_agent_memory

      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_machine_learning_workspace.ai_foundry_project[0].identity[0].principal_id
      }

      env {
        name  = "AI_FOUNDRY_PROJECT_ID"
        value = azurerm_machine_learning_workspace.ai_foundry_project[0].id
      }

      env {
        name  = "OPENAI_ENDPOINT"
        value = module.cognitive_services.resource.endpoint
      }

      dynamic "env" {
        for_each = var.ai_agent_environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  ingress {
    external_enabled = var.ai_agent_external_ingress
    target_port      = var.ai_agent_target_port

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}

# ========================================
# Private Endpoints for AI Foundry Hub and Project
# ========================================
resource "azurerm_private_endpoint" "ai_foundry_hub" {
  for_each = var.ai_foundry_hub_private_endpoints

  name                = each.value.name != null ? each.value.name : "pe-${azurerm_machine_learning_workspace.ai_foundry_hub.name}-${each.key}"
  location            = each.value.location != null ? each.value.location : var.location
  resource_group_name = each.value.resource_group_name != null ? each.value.resource_group_name : azurerm_resource_group.this.name
  subnet_id          = each.value.subnet_resource_id

  private_service_connection {
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "psc-${azurerm_machine_learning_workspace.ai_foundry_hub.name}-${each.key}"
    private_connection_resource_id = azurerm_machine_learning_workspace.ai_foundry_hub.id
    subresource_names             = [each.value.subresource_name]
    is_manual_connection          = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? [each.value.private_dns_zone_group_name] : []
    content {
      name                 = private_dns_zone_group.value
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }

  tags = merge(var.tags, each.value.tags)
}

resource "azurerm_private_endpoint" "ai_foundry_project" {
  for_each = var.create_ai_foundry_project ? var.ai_foundry_project_private_endpoints : {}

  name                = each.value.name != null ? each.value.name : "pe-${azurerm_machine_learning_workspace.ai_foundry_project[0].name}-${each.key}"
  location            = each.value.location != null ? each.value.location : var.location
  resource_group_name = each.value.resource_group_name != null ? each.value.resource_group_name : azurerm_resource_group.this.name
  subnet_id          = each.value.subnet_resource_id

  private_service_connection {
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "psc-${azurerm_machine_learning_workspace.ai_foundry_project[0].name}-${each.key}"
    private_connection_resource_id = azurerm_machine_learning_workspace.ai_foundry_project[0].id
    subresource_names             = [each.value.subresource_name]
    is_manual_connection          = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? [each.value.private_dns_zone_group_name] : []
    content {
      name                 = private_dns_zone_group.value
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }

  tags = merge(var.tags, each.value.tags)
}

# ========================================
