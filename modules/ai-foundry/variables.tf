variable "ai_foundry_name" {
  type        = string
  description = "Name of the AI Foundry account"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
  nullable    = false
}

variable "resource_group_id" {
  type        = string
  description = "Resource group ID for the AI Foundry account"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "ai_foundry_private_endpoints" {
  type = map(object({
    location                        = optional(string)
    name                            = optional(string)
    private_dns_zone_group_name     = optional(string, "default")
    private_dns_zone_resource_ids   = optional(list(string), [])
    private_service_connection_name = optional(string)
    resource_group_name             = optional(string)
    subresource_name                = string
    subnet_resource_id              = string
    tags                            = optional(map(string), {})
  }))
  default     = {}
  description = "Private endpoints for the AI Foundry account"
}

variable "ai_model_deployments" {
  type = map(object({
    name = string
    model = object({
      format  = string
      name    = string
      version = string
    })
    rai_policy_name = optional(string)
    scale = object({
      type     = string
      capacity = optional(number, 1)
    })
    version_upgrade_option = optional(string)
  }))
  default     = {}
  description = "AI model deployments to create"
}

variable "log_analytics_workspace_resource_id" {
  type        = string
  default     = null
  description = "Resource ID of the Log Analytics Workspace for diagnostic settings"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to resources"
}
