variable "ai_agent_host_name" {
  type        = string
  description = "Name of the AI agent capability host"
}

variable "ai_foundry_id" {
  type        = string
  description = "Resource ID of the AI Foundry account"
}

variable "description" {
  type        = string
  description = "Description for the AI Foundry project"
}

variable "display_name" {
  type        = string
  description = "Display name for the AI Foundry project"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
  nullable    = false
}

variable "name" {
  type        = string
  description = "Name of the AI Foundry project"
}

variable "account_capability_host_id" {
  type        = string
  default     = null
  description = "Resource ID of the account-level capability host (if exists) to ensure it completes before project capability host creation"
}

variable "account_user_assigned_identity_principal_ids" {
  type        = list(string)
  default     = []
  description = "Principal IDs of any user-assigned managed identities attached to the parent AI Foundry account. These principals are granted the same Cosmos DB and Storage data-plane roles as the project's system-assigned identity, per the Standard Agent Setup documentation."
  nullable    = false
}

variable "ai_search_id" {
  type        = string
  default     = null
  description = "Resource ID of the AI Search service"
}

variable "cosmos_db_id" {
  type        = string
  default     = null
  description = "Resource ID of the Cosmos DB account"
}

variable "create_ai_agent_service" {
  type        = bool
  default     = true
  description = "Whether to create the AI agent service"
}

variable "create_project_connections" {
  type        = bool
  default     = false
  description = "Whether to create project connections for AI Foundry, Cosmos DB, Key Vault, and AI Search. If set to false, the project will not create connections to these resources."

  validation {
    condition     = !var.create_project_connections || var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0
    error_message = "Project connections require a system-assigned identity or at least one user-assigned identity."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module. For more information see <https://aka.ms/avm/telemetryinfo>. If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

# Preserve the submodule's pre-existing system-assigned identity behavior for callers that omit the new identity input.
# tflint-ignore: avm_interface_managed_identities
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, true)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = { system_assigned = true }
  description = <<DESCRIPTION
Managed identity configuration for the project. The system-assigned identity defaults to enabled to preserve existing behavior.

- `system_assigned` - (Optional) Whether to enable the system-assigned identity. Defaults to true; set explicitly to false for a UAMI-only project.
- `user_assigned_resource_ids` - (Optional) Set of user-assigned identity resource IDs to attach to the project.
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for id in var.managed_identities.user_assigned_resource_ids :
      can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", id))
    ])
    error_message = "Each managed identity must be a valid user-assigned identity resource ID."
  }
}

variable "sku" {
  type        = string
  default     = "S0"
  description = "SKU for the AI Foundry project"
}

variable "storage_account_id" {
  type        = string
  default     = null
  description = "Resource ID of the Storage Account"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to resources"
}
