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

variable "private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "(Optional) The subnet ID for private endpoints."
}

variable "private_dns_zone_resource_id_ai_foundry" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of the private DNS zone for Ai Foundry."
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

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to resources"
}
