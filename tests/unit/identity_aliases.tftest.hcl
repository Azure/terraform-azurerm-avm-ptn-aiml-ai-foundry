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

mock_provider "azurerm" {}

mock_provider "modtm" {}

mock_provider "random" {}

mock_provider "time" {}

override_module {
  target = module.foundry.module.avm_utl_regions
  outputs = {
    regions = [{
      name               = "australiaeast"
      display_name       = "Australia East"
      paired_region_name = "australiasoutheast"
    }]
  }
}

override_resource {
  target = module.foundry.azapi_resource.ai_foundry
}

override_resource {
  target = module.foundry.module.ai_foundry_project["research"].azapi_resource.ai_foundry_project
}

override_data {
  target = module.foundry.data.azapi_resource.ai_foundry_account_keyed
  values = {
    output = { properties = { principalId = "00000000-0000-0000-0000-000000000002" } }
  }
}

override_data {
  target = module.foundry.module.ai_foundry_project["research"].data.azapi_resource.project_user_assigned_identity
  values = {
    output = { properties = { principalId = "00000000-0000-0000-0000-000000000002" } }
  }
}

run "unknown" {
  command = plan

  module {
    source = "./tests/fixtures/unknown-identities"
  }
}
