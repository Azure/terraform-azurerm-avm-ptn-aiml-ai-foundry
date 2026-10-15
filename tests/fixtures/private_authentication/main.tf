module "cosmosdb" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.11.0"

  location                      = "australiaeast"
  name                          = "test-cosmos"
  resource_group_name           = "test"
  enable_telemetry              = false
  local_authentication_disabled = true
  sql_databases                 = {}
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
    time    = time
  }
}
