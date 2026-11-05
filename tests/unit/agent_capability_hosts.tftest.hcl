mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000001"
      tenant_id                = "00000000-0000-0000-0000-000000000003"
      object_id                = "00000000-0000-0000-0000-000000000002"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001"
    }
  }
  mock_data "azapi_resource" {
    defaults = {
      output = { properties = { principalId = "00000000-0000-0000-0000-000000000020" } }
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
  mock_data "azurerm_user_assigned_identity" {
    defaults = {
      principal_id = "00000000-0000-0000-0000-000000000020"
      client_id    = "00000000-0000-0000-0000-000000000021"
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
      identity = { principalId = "00000000-0000-0000-0000-000000000010" }
    }
  }
}

override_resource {
  target = module.ai_foundry_project["research"].azapi_resource.ai_foundry_project
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test-foundry/projects/research"
    output = {
      identity   = { principalId = "00000000-0000-0000-0000-000000000011" }
      properties = { internalId = "00000000000000000000000000000012" }
    }
  }
}

variables {
  base_name                  = "agents"
  location                   = "australiaeast"
  resource_group_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test"
  enable_telemetry           = false
  create_byor                = true
  create_private_endpoints   = false
  ai_foundry = {
    name                           = "test-foundry"
    create_ai_agent_service        = true
    create_account_capability_host = true
    public_network_access_enabled  = false
    network_injections = [{
      scenario                   = "agent"
      subnetArmId                = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/agents"
      useMicrosoftManagedNetwork = false
    }]
  }
  ai_projects = {
    research = {
      name                       = "research"
      display_name               = "Research"
      description                = "Agent capability host regression"
      create_project_connections = true
      user_assigned_identities = {
        application = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
      }
      storage_account_connection = {
        existing_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/testagents"
      }
      cosmos_db_connection = {
        existing_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.DocumentDB/databaseAccounts/test-agents"
      }
      ai_search_connection = {
        existing_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Search/searchServices/test-agents"
      }
    }
  }
}

run "injected_agents_create_account_and_project_hosts_with_cmk" {
  command   = apply
  state_key = "injected"

  variables {
    ai_foundry = {
      name                           = "test-foundry"
      create_ai_agent_service        = true
      create_account_capability_host = true
      public_network_access_enabled  = false
      network_injections = [{
        scenario                   = "agent"
        subnetArmId                = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/agents"
        useMicrosoftManagedNetwork = false
      }]
      user_assigned_identities = {
        application = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
      }
      customer_managed_key = {
        key_vault_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test-agents"
        key_name                           = "test-key"
        key_version                        = "00000000000000000000000000000001"
        user_assigned_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
      }
    }
  }

  assert {
    condition     = length(azapi_resource.ai_agent_capability_host) == 1
    error_message = "VNet-injected agents require one account capability host before the project capability host."
  }
  assert {
    condition     = output.ai_agent_account_capability_host_id != null
    error_message = "The account capability host ID must be exposed for VNet-injected agents."
  }
  assert {
    condition = alltrue([
      for host in azapi_resource.ai_agent_capability_host :
      host.parent_id == output.ai_foundry_id &&
      host.name == "ai-agent-service-${random_string.resource_token.result}" &&
      host.body.properties.capabilityHostKind == "Agents" &&
      host.body.properties.customerSubnet == one(var.ai_foundry.network_injections).subnetArmId &&
      length(keys(host.body.properties)) == 2 &&
      output.ai_agent_account_capability_host_id == host.id
    ])
    error_message = "The account host must retain its parent, released naming formula, Agents kind, and output binding."
  }
  assert {
    condition     = output.ai_agent_service_id["research"] != null
    error_message = "The real project submodule must create its host when agents and BYOR connections are enabled."
  }
  assert {
    condition = (
      azapi_resource.ai_foundry.body.properties.publicNetworkAccess == "Disabled" &&
      azapi_resource.ai_foundry.body.properties.networkInjections == var.ai_foundry.network_injections &&
      azapi_resource.ai_foundry.body.identity.type == "SystemAssigned, UserAssigned" &&
      output.ai_foundry_project_user_assigned_identity_resource_ids["research"] == toset(values(var.ai_projects["research"].user_assigned_identities)) &&
      output.ai_foundry_encryption_status.enabled &&
      length(azapi_update_resource.ai_foundry_cmk) == 1
    )
    error_message = "Creating the host must preserve private network injection, account/project identities, and CMK configuration."
  }
}

run "non_injected_agents_retain_account_and_project_hosts" {
  command   = apply
  state_key = "non_injected"

  variables {
    ai_foundry = {
      name                    = "test-foundry"
      create_ai_agent_service = true
      network_injections      = null
    }
  }

  assert {
    condition = (
      length(azapi_resource.ai_agent_capability_host) == 1 &&
      output.ai_agent_account_capability_host_id == azapi_resource.ai_agent_capability_host[0].id &&
      output.ai_agent_service_id["research"] != null &&
      azapi_resource.ai_foundry.body.properties.networkInjections == null
    )
    error_message = "The released non-injected agent path must keep both hosts and the account host output."
  }
  assert {
    condition     = !contains(keys(azapi_resource.ai_agent_capability_host[0].body.properties), "customerSubnet")
    error_message = "Non-injected hosts must omit customerSubnet rather than send a null or nested object."
  }
}

run "disabled_agents_skip_both_hosts_even_with_injection" {
  command   = apply
  state_key = "disabled"

  variables {
    ai_foundry = {
      name                    = "test-foundry"
      create_ai_agent_service = false
      network_injections = [{
        subnetArmId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/agents"
      }]
    }
  }

  assert {
    condition = (
      length(azapi_resource.ai_agent_capability_host) == 0 &&
      output.ai_agent_account_capability_host_id == null &&
      output.ai_agent_service_id["research"] == null &&
      azapi_resource.ai_foundry.body.properties.networkInjections == null
    )
    error_message = "Disabling agents must omit both hosts, return null IDs, and omit network injection."
  }
}

run "account_host_does_not_require_project_connections" {
  command   = apply
  state_key = "without_connections"

  variables {
    ai_projects = {
      research = {
        name                       = "research"
        display_name               = "Research"
        description                = "No project connections"
        create_project_connections = false
      }
    }
  }

  assert {
    condition = (
      length(azapi_resource.ai_agent_capability_host) == 1 &&
      output.ai_agent_account_capability_host_id == azapi_resource.ai_agent_capability_host[0].id &&
      output.ai_agent_service_id["research"] == null
    )
    error_message = "Explicit account host provisioning does not require project connections; only the project host requires connections."
  }
}

run "injected_default_preserves_platform_host_ownership" {
  command   = apply
  state_key = "platform_owned"

  variables {
    ai_foundry = {
      create_ai_agent_service = true
      network_injections = [{
        subnetArmId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/agents"
      }]
    }
  }

  assert {
    condition = (
      length(azapi_resource.ai_agent_capability_host) == 0 &&
      output.ai_agent_account_capability_host_id == null &&
      output.ai_agent_service_id["research"] != null
    )
    error_message = "Injected accounts must default to platform host ownership and retain the released project path."
  }
}

run "empty_injections_without_opt_in_preserve_released_behavior" {
  command   = apply
  state_key = "empty_default"

  variables {
    ai_foundry = {
      create_ai_agent_service = true
      network_injections      = []
    }
  }

  assert {
    condition     = length(azapi_resource.ai_agent_capability_host) == 0 && output.ai_agent_account_capability_host_id == null
    error_message = "An empty non-null injection list must not implicitly opt into host ownership."
  }
}

run "selects_agent_injection_by_scenario_not_list_position" {
  command   = apply
  state_key = "scenario_selection"

  variables {
    ai_foundry = {
      create_ai_agent_service        = true
      create_account_capability_host = true
      network_injections = [
        {
          scenario    = "none"
          subnetArmId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/unused"
        },
        {
          scenario    = "agent"
          subnetArmId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/agents"
        }
      ]
    }
  }

  assert {
    condition     = azapi_resource.ai_agent_capability_host[0].body.properties.customerSubnet == var.ai_foundry.network_injections[1].subnetArmId
    error_message = "customerSubnet must be the agent injection's string ARM ID, not the first entry or a nested object."
  }
}

run "rejects_opt_in_without_injection" {
  command = plan

  variables {
    ai_foundry = {
      create_ai_agent_service        = true
      create_account_capability_host = true
    }
  }
  expect_failures = [var.ai_foundry]
}

run "rejects_opt_in_with_empty_injections" {
  command = plan

  variables {
    ai_foundry = {
      create_ai_agent_service        = true
      create_account_capability_host = true
      network_injections             = []
    }
  }
  expect_failures = [var.ai_foundry]
}

run "rejects_opt_in_with_disabled_agents" {
  command = plan

  variables {
    ai_foundry = {
      create_ai_agent_service        = false
      create_account_capability_host = true
      network_injections = [{
        subnetArmId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/agents"
      }]
    }
  }
  expect_failures = [var.ai_foundry]
}

run "rejects_ambiguous_agent_injections" {
  command = plan

  variables {
    ai_foundry = {
      create_ai_agent_service        = true
      create_account_capability_host = true
      network_injections = [
        { subnetArmId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/agents" },
        { subnetArmId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/other" }
      ]
    }
  }
  expect_failures = [var.ai_foundry]
}

run "rejects_microsoft_managed_agent_network" {
  command = plan

  variables {
    ai_foundry = {
      create_ai_agent_service        = true
      create_account_capability_host = true
      network_injections = [{
        subnetArmId                = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/agents"
        useMicrosoftManagedNetwork = true
      }]
    }
  }
  expect_failures = [var.ai_foundry]
}

run "rejects_unsupported_injection_scenario" {
  command = plan

  variables {
    ai_foundry = {
      create_ai_agent_service        = true
      create_account_capability_host = true
      network_injections = [{
        scenario    = "unsupported"
        subnetArmId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/agents"
      }]
    }
  }
  expect_failures = [var.ai_foundry]
}

run "rejects_invalid_subnet_arm_id" {
  command = plan

  variables {
    ai_foundry = {
      create_ai_agent_service        = true
      create_account_capability_host = true
      network_injections = [{
        subnetArmId = "not-a-subnet-arm-id"
      }]
    }
  }
  expect_failures = [var.ai_foundry]
}
