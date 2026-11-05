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
      subscription_id = "00000000-0000-0000-0000-000000000001"
      tenant_id       = "00000000-0000-0000-0000-000000000003"
      object_id       = "00000000-0000-0000-0000-000000000002"
    }
  }
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/regression"
    }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/regression/providers/Microsoft.Network/virtualNetworks/regression"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/regression/providers/Microsoft.Network/virtualNetworks/regression/subnets/regression"
    }
  }
  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/regression/providers/Microsoft.Network/privateDnsZones/regression"
    }
  }
  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/regression/providers/Microsoft.OperationalInsights/workspaces/regression"
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}
mock_provider "tls" {}

override_module {
  target = module.regions
  outputs = {
    valid_region_names = ["australiaeast"]
  }
}

override_resource {
  target = random_shuffle.locations
  values = {
    result = ["australiaeast", "australiaeast", "australiaeast"]
  }
}

override_module {
  target = module.naming
  outputs = {
    names = {
      resource_group                 = { name_unique = "rg-regression" }
      virtual_network                = { name_unique = "vnet-regression" }
      public_ip_address              = { name_unique = "pip-regression" }
      bastion_host                   = { name_unique = "bas-regression" }
      compute_virtual_machine        = { name_unique = "vm-regression" }
      virtual_machine_windows        = { name_unique = "vm-regression" }
      network_interface              = { name_unique = "nic-regression" }
      operational_insights_workspace = { name_unique = "law-regression" }
      search_service                 = { name_unique = "search-regression" }
      key_vault_vault                = { name_unique = "kv-regression" }
      storage_account                = { name_unique = "stregression" }
      database_account               = { name_unique = "cosmos-regression" }
      cognitive_services_account     = { name_unique = "foundry-regression" }
    }
  }
}

override_module {
  target  = module.bastion_host
  outputs = {}
}

override_module {
  target  = module.virtual_machine
  outputs = {}
}

override_module {
  target = module.key_vault
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/regression/providers/Microsoft.KeyVault/vaults/kv-regression"
  }
}

override_module {
  target = module.storage_account
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/regression/providers/Microsoft.Storage/storageAccounts/stregression"
  }
}

override_module {
  target = module.cosmosdb
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/regression/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-regression"
  }
}

override_module {
  target = module.ai_foundry.module.avm_utl_regions
  outputs = {
    regions = [{
      name               = "australiaeast"
      display_name       = "Australia East"
      paired_region_name = "australiasoutheast"
    }]
  }
}

override_resource {
  target = azapi_resource.ai_search
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/regression/providers/Microsoft.Search/searchServices/search-regression"
  }
}

override_resource {
  target = module.ai_foundry.azapi_resource.ai_foundry
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/regression/providers/Microsoft.CognitiveServices/accounts/foundry-regression"
    output = {
      identity = { principalId = "00000000-0000-0000-0000-000000000010" }
    }
  }
}

override_resource {
  target = module.ai_foundry.module.ai_foundry_project["project_1"].azapi_resource.ai_foundry_project
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/regression/providers/Microsoft.CognitiveServices/accounts/foundry-regression/projects/project-1"
    output = {
      identity   = { principalId = "00000000-0000-0000-0000-000000000011" }
      properties = { internalId = "00000000000000000000000000000012" }
    }
  }
}

variables {
  enable_telemetry               = false
  create_account_capability_host = true
}

run "injected_byor_example_requires_both_hosts" {
  command   = apply
  state_key = "injected_example"

  module {
    source = "./examples/private-byor"
  }

  assert {
    condition = (
      output.agent_capability_host_ids.account != null &&
      output.agent_capability_host_ids.project != null &&
      output.agent_capability_host_ids.account == module.ai_foundry.ai_agent_account_capability_host_id &&
      output.agent_capability_host_ids.project == module.ai_foundry.ai_agent_service_id["project_1"]
    )
    error_message = "The runnable injected BYOR example must expose both real module host outputs."
  }

  assert {
    condition = (
      module.ai_foundry.storage_account_id["this"] == module.storage_account.resource_id &&
      module.ai_foundry.cosmos_db_id["this"] == module.cosmosdb.resource_id &&
      module.ai_foundry.ai_search_id["this"] == azapi_resource.ai_search.id
    )
    error_message = "The example must retain its BYO Storage, Cosmos DB, and Search selections."
  }

  assert {
    condition = (
      azurerm_subnet.agent_services.delegation[0].service_delegation[0].name == "Microsoft.App/environments" &&
      contains(azurerm_subnet.agent_services.delegation[0].service_delegation[0].actions, "Microsoft.Network/virtualNetworks/subnets/join/action") &&
      azurerm_private_endpoint.pe_aisearch.subnet_id == azurerm_subnet.private_endpoints.id &&
      azurerm_private_endpoint.cosmosdb.subnet_id == azurerm_subnet.private_endpoints.id &&
      azurerm_private_endpoint.pe_aisearch.private_dns_zone_group[0].private_dns_zone_ids == tolist([azurerm_private_dns_zone.search.id]) &&
      azurerm_private_endpoint.cosmosdb.private_dns_zone_group[0].private_dns_zone_ids == tolist([azurerm_private_dns_zone.cosmosdb.id])
    )
    error_message = "Agent subnet delegation, connected-service private endpoints, and DNS wiring must remain configured."
  }
}

run "example_rejects_missing_account_host" {
  command   = plan
  state_key = "missing_account"

  module {
    source = "./examples/private-byor"
  }

  override_module {
    target = module.ai_foundry
    outputs = {
      ai_agent_account_capability_host_id = null
      ai_agent_service_id                 = { project_1 = "project-host" }
    }
  }

  expect_failures = [output.agent_capability_host_ids]
}

run "example_rejects_missing_project_host" {
  command   = plan
  state_key = "missing_project"

  module {
    source = "./examples/private-byor"
  }

  override_module {
    target = module.ai_foundry
    outputs = {
      ai_agent_account_capability_host_id = "account-host"
      ai_agent_service_id                 = { project_1 = null }
    }
  }

  expect_failures = [output.agent_capability_host_ids]
}
