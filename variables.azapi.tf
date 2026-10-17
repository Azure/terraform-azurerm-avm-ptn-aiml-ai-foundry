variable "ignore_body_changes" {
  type = object({
    authorization_role_assignments = optional(list(string), [])
    cognitiveservices_accounts_projects = optional(object({
      authorization_role_assignments = optional(list(string), [])
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths to ignore for consumer-configured role assignments. Empty lists send all configured properties. Ignored configuration is not sent to Azure until the path is removed; changes take effect after apply.

- `authorization_role_assignments` - Paths on account role assignments.
- `cognitiveservices_accounts_projects.authorization_role_assignments` - Paths passed to project role assignments.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    authorization_role_assignments              = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    cognitiveservices_accounts                  = optional(string, "Microsoft.CognitiveServices/accounts@2025-10-01-preview")
    cognitiveservices_accounts_capability_hosts = optional(string, "Microsoft.CognitiveServices/accounts/capabilityHosts@2025-10-01-preview")
    cognitiveservices_accounts_deployments      = optional(string, "Microsoft.CognitiveServices/accounts/deployments@2025-10-01-preview")
    search_search_services                      = optional(string, "Microsoft.Search/searchServices@2024-06-01-preview")
    cognitiveservices_accounts_projects = optional(object({
      authorization_role_assignments                       = optional(string)
      cognitiveservices_accounts_projects                  = optional(string)
      cognitiveservices_accounts_projects_capability_hosts = optional(string)
      cognitiveservices_accounts_projects_connections      = optional(string)
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by this module.

- `authorization_role_assignments` - Resource type and API version for consumer-configured account role assignments.
- `cognitiveservices_accounts` - Resource type and API version for the AI Foundry account. Defaults to `2025-10-01-preview`; use `2025-07-01-preview` for compatibility with AzAPI provider versions that do not include `2025-10-01-preview`.
- `cognitiveservices_accounts_capability_hosts` - Resource type and API version for the account-level AI agent capability host. Defaults to `2025-10-01-preview`; use `2025-07-01-preview` for compatibility with AzAPI provider versions that do not include `2025-10-01-preview`.
- `cognitiveservices_accounts_deployments` - Resource type and API version for AI model deployments. Defaults to `2025-10-01-preview`; use `2025-07-01-preview` for compatibility with AzAPI provider versions that do not include `2025-10-01-preview`.
- `search_search_services` - Resource type and API version for AI Search services created by this pattern module.
- `cognitiveservices_accounts_projects` - Resource type overrides passed to the AI Foundry project submodule.
- `cognitiveservices_accounts_projects.authorization_role_assignments` - Resource type and API version for consumer-configured project role assignments.
- `cognitiveservices_accounts_projects.cognitiveservices_accounts_projects` - Resource type and API version for AI Foundry projects.
- `cognitiveservices_accounts_projects.cognitiveservices_accounts_projects_capability_hosts` - Resource type and API version for project-level AI agent capability hosts.
- `cognitiveservices_accounts_projects.cognitiveservices_accounts_projects_connections` - Resource type and API version for project connections.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["IfMatchPreconditionFailed", "RequestConflict", "CannotDeleteResource", "provisioning state is not terminal", "nested resources exist"])
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = {}
  description = <<DESCRIPTION
Retry configuration applied to supported AzAPI resources declared by this module and its applicable submodules.

- `error_message_regex` - List of regex patterns matching error messages that trigger a retry.
- `interval_seconds` - Initial interval between retries in seconds.
- `max_interval_seconds` - Maximum interval between retries in seconds.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string, "90m")
    read   = optional(string, "5m")
    update = optional(string, "90m")
    delete = optional(string, "90m")
  })
  default     = {}
  description = <<DESCRIPTION
Default per-operation timeouts applied to supported AzAPI resources declared by this module and its applicable submodules. GMU Foundry deployments can exceed 45 minutes, so create, update, and delete default to 90 minutes.

- `create` - Timeout for create operations.
- `read` - Timeout for read operations.
- `update` - Timeout for update operations.
- `delete` - Timeout for delete operations.
DESCRIPTION
}
