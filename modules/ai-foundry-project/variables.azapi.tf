variable "resource_types" {
  type = object({
    cognitiveservices_accounts_projects                  = optional(string, "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview")
    cognitiveservices_accounts_projects_capability_hosts = optional(string, "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview")
    cognitiveservices_accounts_projects_connections      = optional(string, "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the AI Foundry project submodule.

- `cognitiveservices_accounts_projects` - Resource type and API version for AI Foundry projects.
- `cognitiveservices_accounts_projects_capability_hosts` - Resource type and API version for project-level AI agent capability hosts.
- `cognitiveservices_accounts_projects_connections` - Resource type and API version for project connections.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["IfMatchPreconditionFailed", "RequestConflict", "provisioning state is not terminal"])
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = {}
  description = <<DESCRIPTION
Retry configuration applied to supported AzAPI resources declared by the AI Foundry project submodule.

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
Default per-operation timeouts applied to supported AzAPI resources declared by the AI Foundry project submodule.

- `create` - Timeout for create operations.
- `read` - Timeout for read operations.
- `update` - Timeout for update operations.
- `delete` - Timeout for delete operations.
DESCRIPTION
}
