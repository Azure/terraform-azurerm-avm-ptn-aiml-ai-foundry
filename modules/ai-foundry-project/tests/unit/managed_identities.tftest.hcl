mock_provider "azapi" {
  mock_data "azapi_resource" {
    defaults = {
      output = {
        properties = {
          principalId = "00000000-0000-0000-0000-000000000002"
        }
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {}

mock_provider "random" {}

mock_provider "time" {}

run "attaches_user_assigned_identity_without_removing_system_identity" {
  command = plan

  variables {
    ai_agent_host_name         = "test-agent-host"
    ai_foundry_id              = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test"
    description                = "Identity test project"
    display_name               = "Identity test project"
    location                   = "australiaeast"
    name                       = "identity-test-project"
    create_ai_agent_service    = false
    create_project_connections = false
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-uami"]
    }
  }

  assert {
    condition     = azapi_resource.ai_foundry_project.body.identity.type == "SystemAssigned, UserAssigned"
    error_message = "A project with a user-assigned identity must retain its default system-assigned identity."
  }

  assert {
    condition     = contains(keys(azapi_resource.ai_foundry_project.body.identity.userAssignedIdentities), "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-uami")
    error_message = "The project request must include the configured user-assigned identity resource ID."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "preserves_system_identity_when_managed_identities_are_omitted" {
  command = plan

  variables {
    ai_agent_host_name         = "test-agent-host"
    ai_foundry_id              = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test"
    description                = "Identity default test project"
    display_name               = "Identity default test project"
    location                   = "australiaeast"
    name                       = "identity-default-test-project"
    create_ai_agent_service    = false
    create_project_connections = false
  }

  assert {
    condition     = azapi_resource.ai_foundry_project.body.identity.type == "SystemAssigned"
    error_message = "The project submodule must preserve the existing system-assigned identity default."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "supports_user_assigned_identity_without_system_identity" {
  command = plan

  variables {
    ai_agent_host_name         = "test-agent-host"
    ai_foundry_id              = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test"
    description                = "User-assigned only test project"
    display_name               = "User-assigned only test project"
    location                   = "australiaeast"
    name                       = "uami-only-test-project"
    create_ai_agent_service    = false
    create_project_connections = true
    ai_search_id               = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Search/searchServices/test-search"
    cosmos_db_id               = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.DocumentDB/databaseAccounts/test-cosmos"
    storage_account_id         = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/teststorage"
    managed_identities = {
      system_assigned            = false
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-uami"]
    }
  }

  assert {
    condition     = azapi_resource.ai_foundry_project.body.identity.type == "UserAssigned"
    error_message = "A project configured with only a user-assigned identity must emit UserAssigned identity type."
  }

  assert {
    condition = alltrue([
      for assignment in merge(
        azurerm_role_assignment.ai_search_role_assignments,
        azurerm_role_assignment.cosmosdb_role_assignments,
        azurerm_role_assignment.storage_role_assignments
      ) : assignment.principal_id == "00000000-0000-0000-0000-000000000002"
    ]) && length(azurerm_role_assignment.ai_search_role_assignments) == 2
    error_message = "UAMI-only connections must grant the connection roles to the user-assigned principal."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "rejects_connections_without_any_identity" {
  command = plan

  variables {
    ai_agent_host_name         = "test-agent-host"
    ai_foundry_id              = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test"
    description                = "No identity test"
    display_name               = "No identity test"
    location                   = "australiaeast"
    name                       = "no-identity-test"
    create_ai_agent_service    = false
    create_project_connections = true
    managed_identities = {
      system_assigned = false
    }
  }

  expect_failures = [var.create_project_connections]
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}
