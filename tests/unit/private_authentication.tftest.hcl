mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000001"
      tenant_id                = "00000000-0000-0000-0000-000000000003"
      object_id                = "00000000-0000-0000-0000-000000000002"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001"
    }
  }
}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000003"
      subscription_id = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
    }
  }
}

mock_provider "modtm" {}

mock_provider "random" {}

mock_provider "time" {}

override_module {
  target = module.avm_utl_regions
  outputs = {
    regions = [{
      name               = "australiaeast"
      display_name       = "Australia East"
      paired_region_name = "australiasoutheast"
    }]
  }
}

override_resource {
  target = azapi_resource.ai_foundry
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test-foundry"
    output = {
      properties = { endpoint = "https://test-foundry.cognitiveservices.azure.com/" }
      identity   = { principalId = "00000000-0000-0000-0000-000000000010" }
    }
  }
}

variables {
  base_name                  = "testauth"
  location                   = "australiaeast"
  resource_group_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test"
  enable_telemetry           = false
  create_byor                = true
  create_private_endpoints   = false
  ai_foundry = {
    name                    = "test-foundry"
    create_ai_agent_service = false
  }
}

run "sql_account_without_databases_disables_local_authentication" {
  command = apply

  variables {
    cosmosdb_definition = {
      default = { name = "test-cosmos-default" }
      disabled = {
        name                          = "test-cosmos-disabled"
        local_authentication_disabled = true
      }
      enabled = {
        name                          = "test-cosmos-enabled"
        local_authentication_disabled = false
      }
    }
  }

  # Read child outputs backed by the mocked account resource, not root inputs.
  # The root does not configure SQL databases, so the child uses its empty map.
  assert {
    condition = (
      length(module.cosmosdb) == 3 &&
      module.cosmosdb["default"].local_authentication_disabled == true &&
      module.cosmosdb["disabled"].local_authentication_disabled == true &&
      module.cosmosdb["enabled"].local_authentication_disabled == false
    )
    error_message = "The root must forward both explicit authentication values and its secure default to the Cosmos DB child, including accounts with no SQL databases."
  }
  assert {
    condition = alltrue([
      for key, account in module.cosmosdb :
      account.name == var.cosmosdb_definition[key].name
    ])
    error_message = "Each root definition must configure its own Cosmos DB child instance."
  }
}

run "released_auth_wrapper" {
  command = apply

  module {
    source = "./tests/fixtures/private_authentication"
  }

  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
    time    = time
  }

  assert {
    condition     = output.local_authentication_disabled == true
    error_message = "The upstream authentication wrapper must retain its secure SQL API account configuration."
  }
}

run "telemetry_enabled_preserves_wildcard_delete" {
  command = plan

  variables {
    enable_telemetry = true
  }

  assert {
    condition = (
      length(azapi_resource.ai_foundry.delete_headers) == 1 &&
      azapi_resource.ai_foundry.delete_headers["If-Match"] == "*"
    )
    error_message = "Telemetry must not replace the wildcard deletion precondition or add obsolete custom request headers."
  }
}
