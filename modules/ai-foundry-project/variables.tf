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

variable "account_user_assigned_identities" {
  type = map(object({
    resource_id  = string
    principal_id = string
  }))
  default     = {}
  description = "Parent account user-assigned identities keyed by stable, readable aliases, with their ARM resource ID and principal object ID. Values may be unknown at plan time. Reuse the alias in user_assigned_identities when sharing an identity."
  nullable    = false

  validation {
    condition = alltrue([
      for identity in values(var.account_user_assigned_identities) :
      can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", identity.resource_id))
    ])
    error_message = "Each account user-assigned identity resource_id must be a valid user-assigned identity resource ID."
  }
  validation {
    condition = length(distinct([
      for identity in values(var.account_user_assigned_identities) : lower(identity.resource_id)
    ])) == length(var.account_user_assigned_identities)
    error_message = "Account user-assigned identities must use one alias per resource ID."
  }
}

variable "account_user_assigned_identity_principal_ids" {
  type        = list(string)
  default     = []
  description = "Legacy plan-known principal IDs of user-assigned managed identities attached to the parent account. These principals retain their released grant keys. Use account_user_assigned_identities for apply-time principals. Do not supply the same identity through both inputs."
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
    condition     = !var.create_project_connections || var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0 || length(var.user_assigned_identities) > 0
    error_message = "Project connections require a system-assigned identity or at least one user-assigned identity."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
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

variable "user_assigned_identities" {
  type        = map(string)
  default     = {}
  description = "User-assigned identity resource IDs keyed by stable, readable aliases. Use this map for identities created in the same apply; keys must be known during planning, while values may be computed. Reuse the parent's alias for a shared identity. Do not also supply the identity in managed_identities.user_assigned_resource_ids."
  nullable    = false

  validation {
    condition = alltrue([
      for id in values(var.user_assigned_identities) :
      can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", id))
    ])
    error_message = "Each user_assigned_identities value must be a valid user-assigned identity resource ID."
  }
  validation {
    condition = alltrue([
      for key in setintersection(toset(keys(var.user_assigned_identities)), toset(keys(var.account_user_assigned_identities))) :
      lower(var.user_assigned_identities[key]) == lower(var.account_user_assigned_identities[key].resource_id)
    ])
    error_message = "A shared account and project identity alias must refer to the same resource ID."
  }
  validation {
    condition = length(distinct(concat(
      [for id in values(merge({ for key, identity in var.account_user_assigned_identities : key => identity.resource_id }, var.user_assigned_identities)) : lower(id)],
      [for id in var.managed_identities.user_assigned_resource_ids : lower(id)]
    ))) == length(merge(var.account_user_assigned_identities, var.user_assigned_identities)) + length(var.managed_identities.user_assigned_resource_ids)
    error_message = "Use one alias per user-assigned identity across the account and project, and do not also include that identity in managed_identities.user_assigned_resource_ids."
  }
}
