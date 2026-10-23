output "user_assigned_identity_resource_id" {
  description = "The user-assigned identity attached to the AI Foundry account and both projects."

  precondition {
    condition = contains(
      module.ai_foundry.ai_foundry_user_assigned_identity_resource_ids,
      module.user_assigned_identity.resource_id
      ) && contains(
      module.ai_foundry.ai_foundry_project_user_assigned_identity_resource_ids["project_uami_only"],
      module.user_assigned_identity.resource_id
      ) && contains(
      module.ai_foundry.ai_foundry_project_user_assigned_identity_resource_ids["project_both"],
      module.user_assigned_identity.resource_id
    ) && module.ai_foundry.ai_foundry_project_system_identity_principal_id["project_uami_only"] == null && module.ai_foundry.ai_foundry_project_system_identity_principal_id["project_both"] != null
    error_message = "The UAMI must be assigned to the Foundry account and both projects; only project_both should have a system-assigned identity."
  }
  value = module.user_assigned_identity.resource_id
}
