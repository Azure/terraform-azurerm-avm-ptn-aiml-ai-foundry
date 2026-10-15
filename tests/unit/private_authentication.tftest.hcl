mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000003"
      subscription_id = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
    }
  }
}

mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

run "sql_account_without_databases_disables_local_authentication" {
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
    error_message = "SQL API accounts must disable local authentication even when no SQL databases are declared."
  }
}