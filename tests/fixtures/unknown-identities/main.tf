resource "terraform_data" "identity" {
  input = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
}

module "foundry" {
  source = "../../.."

  base_name                  = "unknown"
  location                   = "australiaeast"
  resource_group_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test"
  ai_foundry = {
    name                    = "unknown-foundry"
    create_ai_agent_service = false
    user_assigned_identities = {
      application = terraform_data.identity.output
    }
  }
  ai_projects = {
    research = {
      name                       = "research"
      display_name               = "Research"
      description                = "Unknown identity regression"
      create_project_connections = false
      managed_identities         = { system_assigned = false }
      user_assigned_identities = {
        application = terraform_data.identity.output
      }
    }
  }
  create_byor              = false
  create_private_endpoints = false
  enable_telemetry         = false
}
