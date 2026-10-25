# These computed values remain unknown in the very first plan.
resource "terraform_data" "identity" {
  input = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/application"
}

module "project" {
  source = "../../../modules/ai-foundry-project"

  ai_agent_host_name = "test-agent"
  ai_foundry_id      = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test"
  description        = "Unknown identity regression"
  display_name       = "Unknown identity regression"
  location           = "australiaeast"
  name               = "unknown-identity"
  account_user_assigned_identities = {
    application = {
      resource_id  = terraform_data.identity.output
      principal_id = terraform_data.identity.id
    }
  }
  ai_search_id               = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Search/searchServices/test"
  cosmos_db_id               = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.DocumentDB/databaseAccounts/test"
  create_ai_agent_service    = true
  create_project_connections = true
  enable_telemetry           = false
  managed_identities = {
    system_assigned = false
  }
  storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/test"
  user_assigned_identities = {
    application = terraform_data.identity.output
  }
}
