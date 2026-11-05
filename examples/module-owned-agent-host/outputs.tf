output "agent_capability_host_ids" {
  description = "The module-owned account and project Agent capability host IDs."

  precondition {
    condition = (
      module.private_byor.agent_capability_host_ids.account != null &&
      module.private_byor.agent_capability_host_ids.project != null
    )
    error_message = "Module-owned Agent Service provisioning requires both account and project capability host IDs."
  }
  value = module.private_byor.agent_capability_host_ids
}
