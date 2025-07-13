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

variable "agent_subnet_id" {
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

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of private endpoints to create on the AI Foundry Account.

  - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
  - `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `lock` - (Optional) The lock level to apply to the private endpoint.
  - `tags` - (Optional) A mapping of tags to assign to the private endpoint.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint.
  - `application_security_group_associations` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint.
  - `private_service_connection_name` - (Optional) The name of the private service connection.
  - `network_interface_name` - (Optional) The name of the network interface.
  - `location` - (Optional) The Azure location where the resources will be deployed.
  - `resource_group_name` - (Optional) The resource group where the resources will be deployed.
  - `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint.
  DESCRIPTION
  nullable    = false
}

variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to resources"
}
