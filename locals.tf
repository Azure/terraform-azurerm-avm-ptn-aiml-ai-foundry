# AI Foundry Pattern Module Locals
locals {
  deploy_ai_search = var.existing_ai_search_resource_id == null
  deploy_cosmos_db = var.existing_cosmos_db_resource_id == null
  deploy_key_vault = var.existing_key_vault_resource_id == null
  # Determine if standard resources should be deployed (when BYO resources are not provided)
  deploy_storage_account = var.existing_storage_account_resource_id == null
  # Resource group and location references
  location = var.existing_resource_group_name != null || var.existing_resource_group_id != null ? data.azurerm_resource_group.existing[0].location : var.location
  # Project naming
  project_name        = var.project_name != null ? var.project_name : "${var.name}proj"
  resource_group_id   = var.existing_resource_group_name != null || var.existing_resource_group_id != null ? data.azurerm_resource_group.existing[0].id : azurerm_resource_group.this[0].id
  resource_group_name = var.existing_resource_group_name != null || var.existing_resource_group_id != null ? data.azurerm_resource_group.existing[0].name : azurerm_resource_group.this[0].name
  # Advanced resource naming logic
  # Priority: 1. Custom name, 2. Base name + pattern, 3. var.name + pattern
  resource_names = {
    storage_account = coalesce(
      var.resource_names.storage_account,
      var.base_name != null ? "st${var.base_name}${local.resource_token}" : null,
      "st${var.name}${local.resource_token}"
    )
    key_vault = coalesce(
      var.resource_names.key_vault,
      var.base_name != null ? "kv${var.base_name}${local.resource_token}" : null,
      "kv${var.name}${local.resource_token}"
    )
    cosmos_db = coalesce(
      var.resource_names.cosmos_db,
      var.base_name != null ? "cos${var.base_name}${local.resource_token}" : null,
      "cos${var.name}${local.resource_token}"
    )
    ai_search = coalesce(
      var.resource_names.ai_search,
      var.base_name != null ? "srch${var.base_name}${local.resource_token}" : null,
      "srch${var.name}${local.resource_token}"
    )
    ai_services = coalesce(
      var.resource_names.ai_services,
      var.base_name != null ? "${var.base_name}-aiservices-${local.resource_token}" : null,
      "${var.name}-aiservices-${local.resource_token}"
    )
    ai_foundry_project = coalesce(
      var.resource_names.ai_foundry_project,
      var.ai_foundry_project_name,
      var.base_name != null ? "${var.base_name}proj" : null,
      local.project_name
    )
    ai_agent_host = coalesce(
      var.resource_names.ai_agent_host,
      var.ai_agent_host_name,
      var.base_name != null ? "${var.base_name}-agent-host-${local.resource_token}" : null,
      "${var.name}-agent-host-${local.resource_token}"
    )
    resource_group = coalesce(
      var.resource_names.resource_group,
      var.resource_group_name,
      var.base_name != null ? "rg-${var.base_name}" : null,
      var.resource_group_name
    )
  }
  # Resource token for unique naming
  resource_token = substr(sha256("${data.azurerm_client_config.current.subscription_id}-${local.location}-${var.name}"), 0, 5)
  # Role definition resource substring for role assignments
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  # Networking resource references - prioritize new variables, fallback to deprecated ones
  agent_subnet_id    = var.agent_subnet_resource_id
  subnet_id          = coalesce(var.subnet_resource_id, var.existing_subnet_id)
  virtual_network_id = coalesce(var.virtual_network_resource_id, var.existing_virtual_network_id)
}
