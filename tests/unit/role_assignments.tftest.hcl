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
  target = azapi_resource.role_assignments
}

override_data {
  target = module.avm_interfaces.data.azapi_resource_list.role_definitions
  values = {
    output = {
      results = [{
        role_name = "Reader"
        id        = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
      }]
    }
  }
}

variables {
  base_name                  = "testrbac"
  location                   = "australiaeast"
  resource_group_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test"
  enable_telemetry           = false
  create_byor                = false
  ai_foundry = {
    name                    = "test-foundry"
    create_ai_agent_service = false
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

run "account_alias_attaches_identity_resource_id" {
  command = plan

  variables {
    ai_foundry = {
      name                    = "test-foundry"
      create_ai_agent_service = false
      user_assigned_identities = {
        application = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
      }
    }
  }

  override_data {
    target = data.azapi_resource.ai_foundry_account_keyed
    values = {
      output = { properties = { principalId = "00000000-0000-0000-0000-000000000002" } }
    }
  }

  assert {
    condition = (
      azapi_resource.ai_foundry.body.identity.type == "SystemAssigned, UserAssigned" &&
      toset(keys(azapi_resource.ai_foundry.body.identity.userAssignedIdentities)) == toset(values(var.ai_foundry.user_assigned_identities)) &&
      local.ai_foundry_user_assigned_identity_principals["application"].principal_id == "00000000-0000-0000-0000-000000000002"
    )
    error_message = "The account must attach the real ARM ID, retain its default SMI, and pass the principal under its caller-owned alias."
  }
}

run "account_scope_and_standard_fields" {
  command   = apply
  state_key = "account"

  variables {
    role_assignments = {
      reader = {
        role_definition_id_or_name = "Reader"
        principal_id               = "00000000-0000-0000-0000-000000000002"
        principal_type             = "User"
      }
      delegated = {
        name                                   = "00000000-0000-0000-0000-000000000005"
        role_definition_id_or_name             = "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
        principal_id                           = "00000000-0000-0000-0000-000000000004"
        principal_type                         = "ServicePrincipal"
        description                            = "Account administration"
        condition                              = "!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})"
        condition_version                      = "2.0"
        delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/delegated"
        skip_service_principal_aad_check       = true
      }
    }
  }

  assert {
    condition = length(azapi_resource.role_assignments) == 2 && alltrue([
      for assignment in azapi_resource.role_assignments :
      assignment.parent_id == azapi_resource.ai_foundry.id
    ])
    error_message = "Account assignments must use the exact Foundry account resource ID as scope."
  }
  assert {
    condition = (
      azapi_resource.role_assignments["reader"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" &&
      azapi_resource.role_assignments["reader"].body.properties.principalId == var.role_assignments["reader"].principal_id &&
      azapi_resource.role_assignments["reader"].body.properties.principalType == "User" &&
      azapi_resource.role_assignments["reader"].body.properties.description == null &&
      azapi_resource.role_assignments["reader"].body.properties.condition == null &&
      azapi_resource.role_assignments["reader"].body.properties.conditionVersion == null &&
      azapi_resource.role_assignments["reader"].body.properties.delegatedManagedIdentityResourceId == null &&
      azapi_resource.role_assignments["reader"].name != ""
    )
    error_message = "Role names must resolve, principal IDs/types must forward, and absent optional ARM fields must be null."
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
    error_message = "Role definition IDs and every supported optional field must reach the correct ARM body properties."
  }
  assert {
    condition     = length(azurerm_role_assignment.foundry_role_assignments) == 0 && azapi_resource.ai_foundry.body.identity.type == "SystemAssigned"
    error_message = "New assignments must not duplicate legacy grants or change identity defaults."
  }
}

run "two_projects_keep_assignments_separate" {
  command   = apply
  state_key = "projects"

  variables {
    ai_projects = {
      research = {
        name         = "research"
        display_name = "Research"
        description  = "Research"
        role_assignments = {
          reader = {
            role_definition_id_or_name = "Reader"
            principal_id               = "00000000-0000-0000-0000-000000000002"
            principal_type             = "Group"
          }
        }
      }
      operations = {
        name         = "operations"
        display_name = "Operations"
        description  = "Operations"
        role_assignments = {
          reader = {
            role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
            principal_id               = "00000000-0000-0000-0000-000000000004"
            principal_type             = "ServicePrincipal"
            description                = "Project operations"
          }
        }
      }
    }
  }

  override_resource {
    target = module.ai_foundry_project["research"].azapi_resource.ai_foundry_project
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test-foundry/projects/research"
      output = {
        properties = { internalId = "research" }
        identity   = { principalId = "00000000-0000-0000-0000-000000000011" }
      }
    }
  }
  override_resource {
    target = module.ai_foundry_project["operations"].azapi_resource.ai_foundry_project
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test-foundry/projects/operations"
      output = {
        properties = { internalId = "operations" }
        identity   = { principalId = "00000000-0000-0000-0000-000000000012" }
      }
    }
  }

  override_resource {
    target = module.ai_foundry_project["research"].azapi_resource.role_assignments
  }
  override_resource {
    target = module.ai_foundry_project["operations"].azapi_resource.role_assignments
  }
  override_data {
    target = module.ai_foundry_project["research"].module.avm_interfaces.data.azapi_resource_list.role_definitions
    values = {
      output = {
        results = [{
          role_name = "Reader"
          id        = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        }]
      }
    }
  }

  override_data {
    target = module.ai_foundry_project["operations"].module.avm_interfaces.data.azapi_resource_list.role_definitions
    values = {
      output = {
        results = [{
          role_name = "Reader"
          id        = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        }]
      }
    }
  }

  assert {
    condition = alltrue([
      for key, project in module.ai_foundry_project :
      length(project.role_assignments) == 1 &&
      project.role_assignments["reader"].scope == "${azapi_resource.ai_foundry.id}/projects/${var.ai_projects[key].name}" &&
      project.role_assignments["reader"].principal_id == var.ai_projects[key].role_assignments["reader"].principal_id
    ])
    error_message = "The same assignment key on two projects must remain independent with each project's exact scope and principal."
  }
  assert {
    condition = (
      module.ai_foundry_project["research"].role_assignments["reader"].role_definition_id == "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" &&
      module.ai_foundry_project["operations"].role_assignments["reader"].role_definition_id == var.ai_projects["operations"].role_assignments["reader"].role_definition_id_or_name &&
      module.ai_foundry_project["research"].role_assignments["reader"].scope != module.ai_foundry_project["operations"].role_assignments["reader"].scope &&
      length(azapi_resource.role_assignments) == 0 &&
      length(module.ai_foundry_project) == 2
    )
    error_message = "Project roles must resolve independently and project-only assignments must not create account grants."
  }
}

run "omitted_maps_create_no_assignments" {
  command   = apply
  state_key = "defaults"

  variables {
    ai_projects = {
      research = {
        name         = "research"
        display_name = "Research"
        description  = "Research without optional RBAC"
      }
    }
  }

  override_resource {
    target = module.ai_foundry_project["research"].azapi_resource.ai_foundry_project
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test-foundry/projects/research"
      output = {
        properties = { internalId = "research" }
        identity   = { principalId = "00000000-0000-0000-0000-000000000011" }
      }
    }
  }

  assert {
    condition = (
      length(azapi_resource.role_assignments) == 0 &&
      length(module.avm_interfaces.role_assignments_azapi) == 0 &&
      length(azurerm_role_assignment.foundry_role_assignments) == 0 &&
      length(module.ai_foundry_project["research"].role_assignments) == 0 &&
      azapi_resource.ai_foundry.body.identity.type == "SystemAssigned"
    )
    error_message = "Omitting both account and project maps must preserve the no-assignment behavior."
  }
}

run "legacy_account_interface_remains_independent" {
  command   = apply
  state_key = "legacy"

  variables {
    ai_foundry = {
      name                    = "test-foundry"
      create_ai_agent_service = false
      role_assignments = {
        legacy_reader = {
          role_definition_id_or_name = "Reader"
          principal_id               = "00000000-0000-0000-0000-000000000002"
        }
      }
    }
  }

  assert {
    condition = (
      length(azapi_resource.role_assignments) == 0 &&
      length(azurerm_role_assignment.foundry_role_assignments) == 1 &&
      azurerm_role_assignment.foundry_role_assignments["legacy_reader"].scope == azapi_resource.ai_foundry.id
    )
    error_message = "Existing nested account grants must retain their resource addresses and scope."
  }
}

run "reject_invalid_delegated_identity" {
  command   = plan
  state_key = "invalid"

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
}
