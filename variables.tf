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

variable "ai_model_deployments" {
  type = map(object({
    name                   = string
    rai_policy_name        = optional(string)
    version_upgrade_option = optional(string, "OnceNewDefaultVersionAvailable")
    model = object({
      format  = string
      name    = string
      version = string
    })
    scale = object({
      capacity = optional(number)
      family   = optional(string)
      size     = optional(string)
      tier     = optional(string)
      type     = string
    })
  }))
  default     = {}
  description = <<DESCRIPTION
Configuration for AI model deployments (including OpenAI). Each deployment includes:
- `name` - The name of the deployment
- `rai_policy_name` - (Optional) The name of the RAI policy
- `version_upgrade_option` - (Optional) How to handle version upgrades (default: "OnceNewDefaultVersionAvailable")
- `model` - The model configuration:
  - `format` - The format of the model (e.g., "OpenAI")
  - `name` - The name of the model to deploy
  - `version` - The version of the model
- `scale` - The scaling configuration:
  - `type` - The scaling type (e.g., "Standard")
  - `capacity` - (Optional) The capacity of the deployment
  - `family` - (Optional) The family of the deployment
  - `size` - (Optional) The size of the deployment
  - `tier` - (Optional) The pricing tier for the deployment
DESCRIPTION
}

variable "create_byor" {
  type        = bool
  default     = false
  description = "Whether to create resources such as AI Search, Cosmos DB, Key Vault, and Storage Account in this deployment. If set to false, these resources will not be created or linked, and the module will only create the AI Foundry account and project."
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
