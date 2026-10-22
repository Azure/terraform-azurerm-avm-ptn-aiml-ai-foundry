mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      output = {
        identity   = { principalId = "00000000-0000-0000-0000-000000000010" }
        properties = { internalId = "0123456789abcdef0123456789abcdef" }
      }
    }
  }
  mock_data "azapi_resource" {
    defaults = {
      output = {
        properties = { principalId = "00000000-0000-0000-0000-000000000002" }
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

mock_provider "time" {}

variables {
  ai_agent_host_name         = "test-agent"
  ai_foundry_id              = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test"
  description                = "Identity alias regression"
  display_name               = "Identity alias regression"
  location                   = "australiaeast"
  name                       = "alias-project"
  ai_search_id               = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Search/searchServices/test"
  cosmos_db_id               = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.DocumentDB/databaseAccounts/test"
  storage_account_id         = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/test"
  create_ai_agent_service    = true
  create_project_connections = true
  enable_telemetry           = false
}

run "unknown" {
  command = plan

  module {
    source = "../../tests/fixtures/unknown-project-identities"
  }
}

run "shared_alias_creates_one_grant_and_preserves_azure_names" {
  command = plan

  variables {
    managed_identities = { system_assigned = false }
    user_assigned_identities = {
      application = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
    }
    account_user_assigned_identities = {
      application = {
        resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
        principal_id = "00000000-0000-0000-0000-000000000002"
      }
    }
  }

  assert {
    condition = (
      azapi_resource.ai_foundry_project.body.identity.type == "UserAssigned" &&
      toset(keys(azapi_resource.ai_foundry_project.body.identity.userAssignedIdentities)) == toset(values(var.user_assigned_identities))
    )
    error_message = "The alias map must attach the actual identity ARM ID, not the tracking alias, without enabling the system identity."
  }
  assert {
    condition = (
      keys(azurerm_cosmosdb_sql_role_assignment.enterprise_memory_db_account_umi) == ["identity:application"] &&
      keys(azurerm_role_assignment.storage_blob_data_owner_account_umi) == ["identity:application"] &&
      length(azurerm_cosmosdb_sql_role_assignment.enterprise_memory_db_project_smi) == 0 &&
      length(azurerm_role_assignment.storage_blob_data_owner_project_smi) == 0
    )
    error_message = "A shared alias must produce one dependent-service grant, without any SMI grant for a UAMI-only project."
  }
  assert {
    condition = (
      azurerm_cosmosdb_sql_role_assignment.enterprise_memory_db_account_umi["identity:application"].name == uuidv5("dns", "alias-project-accountumi-00000000-0000-0000-0000-000000000002-enterprisememory_dbsqlrole") &&
      azurerm_role_assignment.storage_blob_data_owner_account_umi["identity:application"].name == uuidv5("dns", "alias-project-accountumi-00000000-0000-0000-0000-000000000002-teststorageblobdataowner")
    )
    error_message = "Azure assignment names must remain derived from principal IDs, not tracking aliases."
  }
}

run "user_alias_cannot_overwrite_system_identity_or_legacy_keys" {
  command = plan

  variables {
    user_assigned_identities = {
      system_assigned = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
    }
    account_user_assigned_identity_principal_ids = ["00000000-0000-0000-0000-000000000003"]
  }

  assert {
    condition = (
      contains(keys(azurerm_role_assignment.ai_search_role_assignments), "search_index_data_contributor") &&
      contains(keys(azurerm_role_assignment.ai_search_role_assignments), "identity:system_assigned:search_index_data_contributor") &&
      length(azurerm_role_assignment.ai_search_role_assignments) == 4 &&
      contains(keys(azurerm_role_assignment.storage_blob_data_owner_account_umi), "00000000-0000-0000-0000-000000000003")
    )
    error_message = "SMI connection keys and released principal-ID grant keys must remain intact even for a reserved-looking user alias."
  }
}

run "rejects_different_ids_under_shared_alias" {
  command = plan

  variables {
    user_assigned_identities = {
      application = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
    }
    account_user_assigned_identities = {
      application = {
        resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/other"
        principal_id = "00000000-0000-0000-0000-000000000003"
      }
    }
  }

  expect_failures = [var.user_assigned_identities]
}

run "rejects_duplicate_ids_under_different_aliases" {
  command = plan

  variables {
    user_assigned_identities = {
      first  = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
      second = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
    }
  }

  expect_failures = [var.user_assigned_identities]
}

run "rejects_duplicate_ids_across_old_and_new_inputs" {
  command = plan

  variables {
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"]
    }
    user_assigned_identities = {
      application = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
    }
  }

  expect_failures = [var.user_assigned_identities]
}

run "rejects_invalid_identity_id" {
  command = plan

  variables {
    user_assigned_identities = { application = "not-an-arm-id" }
  }

  expect_failures = [var.user_assigned_identities]
}

run "rejects_duplicate_legacy_and_alias_principals" {
  command = plan

  variables {
    managed_identities                           = { system_assigned = false }
    account_user_assigned_identity_principal_ids = ["00000000-0000-0000-0000-000000000002"]
    user_assigned_identities = {
      application = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
    }
  }

  expect_failures = [
    azurerm_cosmosdb_sql_role_assignment.enterprise_memory_db_account_umi,
    azurerm_role_assignment.storage_blob_data_owner_account_umi,
  ]
}

run "agent_without_connections_has_no_capability_host" {
  command = plan

  variables {
    create_project_connections = false
  }

  assert {
    condition     = output.ai_agent_capability_host_id == null
    error_message = "The capability-host output must match the resource's creation condition."
  }
}

run "aliases_added" {
  command   = apply
  state_key = "stable-aliases"

  variables {
    create_ai_agent_service    = false
    create_project_connections = false
    user_assigned_identities = {
      application = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
      worker      = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/worker"
    }
  }

  assert {
    condition     = keys(data.azapi_resource.project_user_assigned_identity) == ["identity:application", "identity:worker"]
    error_message = "Lookup instances must use caller-owned aliases."
  }
}

run "alias_order_is_irrelevant" {
  command   = apply
  state_key = "stable-aliases"

  variables {
    create_ai_agent_service    = false
    create_project_connections = false
    user_assigned_identities = {
      worker      = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/worker"
      application = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
    }
  }

  assert {
    condition     = output.resource_id == run.aliases_added.resource_id && keys(data.azapi_resource.project_user_assigned_identity) == ["identity:application", "identity:worker"]
    error_message = "Reordering map entries must retain the project and its lookup instance keys."
  }
}

run "removing_alias_retains_other_instances" {
  command   = apply
  state_key = "stable-aliases"

  variables {
    create_ai_agent_service    = false
    create_project_connections = false
    user_assigned_identities = {
      application = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
    }
  }

  assert {
    condition     = output.resource_id == run.aliases_added.resource_id && keys(data.azapi_resource.project_user_assigned_identity) == ["identity:application"]
    error_message = "Removing a user alias must not renumber surviving lookup instances or replace the project."
  }
}
