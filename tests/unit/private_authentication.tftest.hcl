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

run "sql_account_without_databases_disables_local_authentication" {
  command = apply

  module {
    source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
    version = "0.11.0"
  }

  variables {
    location                      = "australiaeast"
    name                          = "test-cosmos"
    resource_group_name           = "test"
    enable_telemetry              = false
    local_authentication_disabled = true
    sql_databases                 = {}
  }

  assert {
    condition     = output.local_authentication_disabled == true
    error_message = "SQL API accounts must disable local authentication even when no SQL databases are declared."
  }
}