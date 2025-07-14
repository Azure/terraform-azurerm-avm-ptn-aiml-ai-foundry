variable "ai_foundry_name" {
  type        = string
  description = "Name of the AI Foundry account"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
  nullable    = false
}

variable "resource_group_resource_id" {
  type        = string
  description = "Resource group ID for the AI Foundry account"
}

variable "agent_subnet_resource_id" {
  type        = string
  default     = null
  description = "(Optional) The subnet ID for the AI agent service."
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

variable "create_ai_agent_service" {
  type        = bool
  default     = false
  description = "Whether to create the AI agent service. If set to false, the AI agent service will not be created, and the AI Foundry account will not have any AI agent capabilities."
}

variable "create_private_endpoints" {
  type        = bool
  default     = false
  description = "Whether to create private endpoints for AI Foundry, Cosmos DB, Key Vault, and AI Search. If set to false, private endpoints will not be created, and the resources will be accessible over public endpoints. This is useful for scenarios where private connectivity is not required or when using existing resources that do not require private endpoints."
}

variable "private_dns_zone_resource_id_ai_foundry" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of the private DNS zone for Ai Foundry."
}

variable "private_endpoint_subnet_resource_id" {
  type        = string
  default     = null
  description = "(Optional) The subnet ID for private endpoints."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to resources"
}
