output "agent_capability_host_ids" {
  description = "Account and project capability host IDs for the VNet-injected standard Agent Service regression."

  precondition {
    condition     = !var.create_account_capability_host || module.ai_foundry.ai_agent_account_capability_host_id != null
    error_message = "Explicit account capability host provisioning must expose the managed host ID before the project capability host."
  }
  precondition {
    condition     = module.ai_foundry.ai_agent_service_id["project_1"] != null
    error_message = "The project with BYO Storage, Cosmos DB, and Search connections must create its capability host."
  }
  value = {
    account = module.ai_foundry.ai_agent_account_capability_host_id
    project = module.ai_foundry.ai_agent_service_id["project_1"]
  }
}
