variable "base_name" {
  type        = string
  description = "The name prefix for the AI Foundry resources."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,7}[a-z0-9]$", var.base_name))
    error_message = "Base name to use as affix for resource names when custom names are not provided. The base_name must be between 3 and 7 characters long, start and end with alphanumeric characters, and can only contain lowercase letters, numbers, and hyphens."
  }
}

variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "resource_group_resource_id" {
  type        = string
  description = "The resource group resource id where the module resources will be deployed."
}

variable "create_byor" {
  type        = bool
  default     = false
  description = "Whether to create resources such as AI Search, Cosmos DB, Key Vault, and Storage Account in this deployment. If set to false, these resources will not be created or linked, and the module will only create the AI Foundry account and project."
}

variable "create_byor_cmk" {
  type        = bool
  default     = false
  description = "Whether to create a customer-managed key (CMK) in Key Vault for BYOR resources. If set to true, a Key Vault will be created and used for the CMK for all BYOR resources which get created as part of this module. Only works if `create_byor` is true."
}

variable "create_private_endpoints" {
  type        = bool
  default     = false
  description = "Whether to create private endpoints for AI Foundry, Cosmos DB, Key Vault, and AI Search. If set to false, private endpoints will not be created."
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

variable "private_endpoint_subnet_resource_id" {
  type        = string
  default     = null
  description = "(Optional) The subnet ID for private endpoints."
}

#TODO: Move the project relating naming to a separate projects map so we can create multiple projects in the same module. (Then separate the remaining names into individual variables?)
variable "resource_names" {
  type = object({
    ai_agent_host                   = optional(string)
    ai_foundry                      = optional(string)
    ai_foundry_project              = optional(string)
    ai_foundry_project_display_name = optional(string)
  })
  default     = {}
  description = "Custom names for each resource. If not provided, names will be generated using base_name or name."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags to be applied to all resources."
}
