###############################################################################
# Azure AI Foundry (AVM pattern module, BYOR mode)
#
# create_byor              = false -> the module does not create any dependent
#                                     data service; it consumes the ones above.
# create_private_endpoints = true  -> the module creates the Foundry account
#                                     private endpoint in the landing zone
#                                     private endpoint subnet.
###############################################################################

module "ai_foundry" {
  source  = "Azure/avm-ptn-aiml-ai-foundry/azurerm"
  version = "0.11.3"

  base_name                  = var.base_name
  location                   = var.location
  resource_group_resource_id = local.resource_group_resource_id
  ai_foundry = {
    name                     = local.names.ai_foundry
    sku                      = var.ai_foundry.sku
    allow_project_management = var.ai_foundry.allow_project_management
    disable_local_auth       = var.ai_foundry.disable_local_auth
    create_ai_agent_service  = var.ai_foundry.create_ai_agent_service

    # Standard Agent setup: agents run injected into the landing zone spoke.
    network_injections = var.ai_foundry.create_ai_agent_service ? [{
      scenario                   = "agent"
      subnetArmId                = local.agent_subnet_resource_id
      useMicrosoftManagedNetwork = false
    }] : null

    private_dns_zone_resource_ids = local.foundry_private_dns_zone_resource_ids
    public_network_access_enabled = false
    network_acls = {
      bypass         = "AzureServices"
      default_action = "Deny"
    }

    role_assignments = var.ai_foundry.role_assignments
  }
  ai_model_deployments = var.ai_model_deployments
  ai_projects          = local.ai_projects

  # BYOR: the dependent services are owned by this configuration, not the module.
  create_byor = false
  ai_search_definition = {
    this = {
      existing_resource_id = azapi_resource.ai_search.id
    }
  }
  cosmosdb_definition = {
    this = {
      existing_resource_id = module.cosmosdb.resource_id
    }
  }
  storage_account_definition = {
    this = {
      existing_resource_id = module.storage_account.resource_id
    }
  }
  key_vault_definition = var.deploy_key_vault ? {
    this = {
      existing_resource_id = module.key_vault[0].resource_id
    }
  } : {}

  create_private_endpoints                 = true
  private_endpoint_subnet_resource_id      = var.private_endpoint_subnet_resource_id
  private_endpoints_manage_dns_zone_groups = var.manage_private_dns_zone_groups

  diagnostic_settings = local.diagnostic_settings
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags

  depends_on = [
    azurerm_private_endpoint.cosmosdb,
    azurerm_private_endpoint.cosmosdb_unmanaged_dns,
    azurerm_private_endpoint.ai_search,
    azurerm_private_endpoint.ai_search_unmanaged_dns,
    azapi_resource_action.purge_ai_foundry,
  ]
}

###############################################################################
# Optional destroy-time purge of the soft-deleted Cognitive Services account.
#
# Without this, the account name stays reserved for the soft-delete window and
# the service association link on the delegated agent subnet is not released,
# which blocks a re-deploy into the same subnet.
###############################################################################

resource "time_sleep" "agent_subnet_release" {
  count = var.purge_soft_deleted_foundry_on_destroy ? 1 : 0

  destroy_duration = "20m"

  depends_on = [azurerm_subnet.agent]
}

resource "azapi_resource_action" "purge_ai_foundry" {
  count = var.purge_soft_deleted_foundry_on_destroy ? 1 : 0

  method      = "DELETE"
  resource_id = "/subscriptions/${coalesce(var.subscription_id, data.azurerm_client_config.current.subscription_id)}/providers/Microsoft.CognitiveServices/locations/${var.location}/resourceGroups/${local.resource_group_name}/deletedAccounts/${local.names.ai_foundry}"
  type        = "Microsoft.CognitiveServices/locations/resourceGroups/deletedAccounts@2025-09-01"
  retry = {
    error_message_regex  = ["RequestConflict"]
    interval_seconds     = 30
    max_interval_seconds = 120
  }
  when = "destroy"

  depends_on = [time_sleep.agent_subnet_release]
}
