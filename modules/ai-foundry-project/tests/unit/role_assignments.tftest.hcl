mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001"
    }
  }
  mock_resource "azapi_resource" {
    defaults = {
      tags = {}
      output = {
        properties = { internalId = "project-internal-id" }
        identity   = { principalId = "00000000-0000-0000-0000-000000000010" }
      }
    }
  }
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [{
          role_name = "Reader"
          id        = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        }]
      }
    }
  }
}

mock_provider "azurerm" {}

mock_provider "time" {}

mock_provider "random" {}

variables {
  ai_agent_host_name         = "test-agent"
  ai_foundry_id              = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test"
  name                       = "research"
  display_name               = "Research"
  description                = "Research project"
  location                   = "australiaeast"
  create_ai_agent_service    = false
  create_project_connections = false
}

override_resource {
  target = azapi_resource.ai_foundry_project
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test/projects/research"
    output = {
      properties = { internalId = "research" }
      identity   = { principalId = "00000000-0000-0000-0000-000000000010" }
    }
  }
}

run "telemetry_omits_tags_without_disabling_project_tags" {
  command = apply

  variables {
    enable_telemetry = true
    tags = {
      environment = "unit"
    }
  }

  assert {
    condition = (
      length(azapi_resource.telemetry) == 1 &&
      length(azapi_resource.telemetry[0].tags) == 0 &&
      azapi_resource.telemetry[0].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000001" &&
      length(azapi_resource.telemetry[0].body.properties.template.resources) == 0
    )
    error_message = "SFR3 telemetry must remain an empty subscription deployment without consumer tags."
  }

  assert {
    condition     = azapi_resource.ai_foundry_project.tags == var.tags
    error_message = "The telemetry-only tag exemption must not change the project's consumer tags."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "standalone_project_assignments" {
  command = apply

  variables {
    role_assignments = {
      reader = {
        role_definition_id_or_name = "Reader"
        principal_id               = "00000000-0000-0000-0000-000000000002"
        principal_type             = "Group"
      }
      minimal = {
        role_definition_id_or_name = "Reader"
        principal_id               = "00000000-0000-0000-0000-000000000006"
      }
      delegated = {
        name                                   = "00000000-0000-0000-0000-000000000003"
        role_definition_id_or_name             = "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
        principal_id                           = "00000000-0000-0000-0000-000000000004"
        principal_type                         = "ServicePrincipal"
        description                            = "Delegated project access"
        condition                              = "!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})"
        condition_version                      = "2.0"
        delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/delegated"
        skip_service_principal_aad_check       = true
      }
    }
  }

  assert {
    condition = length(azapi_resource.role_assignments) == 3 && alltrue([
      for assignment in azapi_resource.role_assignments :
      assignment.parent_id == azapi_resource.ai_foundry_project.id
    ])
    error_message = "All assignments must target the exact project, not the account."
  }
  assert {
    condition = (
      azapi_resource.role_assignments["minimal"].body.properties.principalType == null &&
      azapi_resource.role_assignments["minimal"].body.properties.condition == null &&
      azapi_resource.role_assignments["minimal"].body.properties.conditionVersion == null &&
      azapi_resource.role_assignments["minimal"].body.properties.description == null &&
      azapi_resource.role_assignments["minimal"].body.properties.delegatedManagedIdentityResourceId == null &&
      !contains(keys(azapi_resource.role_assignments["minimal"].body.properties), "principal_id")
    )
    error_message = "A minimal assignment must not inject a principal type, condition, description, delegation, or snake_case ARM property."
  }
  assert {
    condition = (
      azapi_resource.role_assignments["reader"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" &&
      azapi_resource.role_assignments["reader"].body.properties.principalId == var.role_assignments["reader"].principal_id &&
      azapi_resource.role_assignments["reader"].body.properties.principalType == "Group" &&
      azapi_resource.role_assignments["reader"].body.properties.condition == null &&
      azapi_resource.role_assignments["reader"].body.properties.conditionVersion == null &&
      azapi_resource.role_assignments["reader"].body.properties.description == null &&
      azapi_resource.role_assignments["reader"].body.properties.delegatedManagedIdentityResourceId == null &&
      azapi_resource.role_assignments["reader"].name != ""
    )
    error_message = "Named roles must resolve and minimal assignments must preserve null optional ARM properties."
  }
  assert {
    condition = (
      azapi_resource.role_assignments["delegated"].name == var.role_assignments["delegated"].name &&
      azapi_resource.role_assignments["delegated"].body.properties.roleDefinitionId == var.role_assignments["delegated"].role_definition_id_or_name &&
      azapi_resource.role_assignments["delegated"].body.properties.principalId == var.role_assignments["delegated"].principal_id &&
      azapi_resource.role_assignments["delegated"].body.properties.principalType == "ServicePrincipal" &&
      azapi_resource.role_assignments["delegated"].body.properties.description == var.role_assignments["delegated"].description &&
      azapi_resource.role_assignments["delegated"].body.properties.condition == var.role_assignments["delegated"].condition &&
      azapi_resource.role_assignments["delegated"].body.properties.conditionVersion == "2.0" &&
      azapi_resource.role_assignments["delegated"].body.properties.delegatedManagedIdentityResourceId == var.role_assignments["delegated"].delegated_managed_identity_resource_id &&
      !contains(keys(azapi_resource.role_assignments["delegated"].body.properties), "skip_service_principal_aad_check")
    )
    error_message = "Standard optional fields must reach the correctly cased ARM body; skip_service_principal_aad_check is not an ARM property."
  }
  assert {
    condition     = output.role_assignments["reader"].scope == azapi_resource.ai_foundry_project.id && output.role_assignments["delegated"].principal_id == var.role_assignments["delegated"].principal_id
    error_message = "The project assignment summary must reflect deployed assignment properties."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "empty_defaults_preserve_project_behavior" {
  command = apply

  assert {
    condition = (
      length(azapi_resource.role_assignments) == 0 &&
      length(module.avm_interfaces.role_assignments_azapi) == 0 &&
      length(output.role_assignments) == 0 &&
      azapi_resource.ai_foundry_project.body.identity.type == "SystemAssigned" &&
      length(azapi_resource.connection_storage) == 0 &&
      length(azurerm_role_assignment.storage_role_assignments) == 0
    )
    error_message = "Omitting role assignments must create no grants and preserve identity and connection defaults."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "reject_invalid_delegated_identity" {
  command = plan

  variables {
    role_assignments = {
      invalid = {
        role_definition_id_or_name             = "Reader"
        principal_id                           = "00000000-0000-0000-0000-000000000002"
        delegated_managed_identity_resource_id = "/not/an/identity"
      }
    }
  }
  expect_failures = [var.role_assignments]
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "forwards_azapi_controls" {
  command = apply

  variables {
    role_assignments = {
      reader = {
        role_definition_id_or_name = "Reader"
        principal_id               = "00000000-0000-0000-0000-000000000002"
      }
    }
    retry = {
      error_message_regex  = ["ScopeLocked"]
      interval_seconds     = 15
      max_interval_seconds = 60
    }
    timeouts = {
      create = "10m"
      read   = "2m"
      update = "10m"
      delete = "5m"
    }
    ignore_body_changes = {
      authorization_role_assignments = ["properties.description"]
    }
  }

  assert {
    condition = (
      azapi_resource.role_assignments["reader"].type == var.resource_types.authorization_role_assignments &&
      azapi_resource.role_assignments["reader"].retry.interval_seconds == 15 &&
      azapi_resource.role_assignments["reader"].retry.max_interval_seconds == 60 &&
      azapi_resource.role_assignments["reader"].timeouts.create == "10m" &&
      azapi_resource.role_assignments["reader"].timeouts.delete == "5m" &&
      azapi_resource.role_assignments["reader"].ignore_body_changes == null &&
      length(azapi_resource.role_assignments["reader"].response_export_values) == 0
    )
    error_message = "Consumer role assignments must honor AzAPI type, retry, timeout and response-export controls; write-only ignore_body_changes must not persist in state."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}
