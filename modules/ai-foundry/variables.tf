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

variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
  })
  default     = null
  description = "Configuration for Customer Managed Key (CMK) encryption for AI Foundry."
}

# Full AI Foundry account properties based on Microsoft.CognitiveServices/accounts API
variable "kind" {
  type        = string
  default     = "AIServices"
  description = "The kind of the Cognitive Services account. For AI Foundry, this should be 'AIServices'."

  validation {
    condition = contains([
      "AIServices", "CognitiveServices", "ComputerVision", "ContentModerator", "Face",
      "FormRecognizer", "ImmersiveReader", "LUIS", "Personalizer", "QnAMaker",
      "SpeechServices", "TextAnalytics", "TextTranslation"
    ], var.kind)
    error_message = "The kind must be a valid Cognitive Services account kind."
  }
}

variable "sku_name" {
  type        = string
  default     = "S0"
  description = "The SKU name for the Cognitive Services account."

  validation {
    condition = contains([
      "F0", "F1", "S0", "S1", "S2", "S3", "S4", "S5", "S6", "E0"
    ], var.sku_name)
    error_message = "The SKU name must be a valid Cognitive Services SKU."
  }
}

variable "identity_type" {
  type        = string
  default     = "SystemAssigned"
  description = "The type of managed identity for the account."

  validation {
    condition = contains([
      "None", "SystemAssigned", "UserAssigned", "SystemAssigned,UserAssigned"
    ], var.identity_type)
    error_message = "The identity type must be None, SystemAssigned, UserAssigned, or SystemAssigned,UserAssigned."
  }
}

variable "user_assigned_identity_ids" {
  type        = list(string)
  default     = []
  description = "The list of user assigned identity IDs to assign to the account."
}

variable "api_properties" {
  type = object({
    aadClientId                        = optional(string)
    aadTenantId                        = optional(string)
    eventHubConnectionString           = optional(string)
    qnaAzureSearchEndpointId           = optional(string)
    qnaAzureSearchEndpointKey          = optional(string)
    qnaRuntimeEndpoint                 = optional(string)
    statisticsEnabled                  = optional(bool)
    superUser                          = optional(string)
    websiteName                        = optional(string)
  })
  default     = {}
  description = "API-specific properties for the Cognitive Services account."
}

variable "custom_sub_domain_name" {
  type        = string
  default     = null
  description = "The subdomain name used for token-based authentication. When not specified, the account name will be used."
}

variable "disable_local_auth" {
  type        = bool
  default     = false
  description = "Whether to disable local authentication methods in favor of AAD authentication."
}

variable "dynamic_throttling_enabled" {
  type        = bool
  default     = null
  description = "Whether to enable dynamic throttling."
}

variable "fqdn" {
  type        = string
  default     = null
  description = "The fully qualified domain name for the account."
}

variable "migration_token" {
  type        = string
  default     = null
  description = "The migration token for the account."
}

variable "network_acls" {
  type = object({
    default_action = optional(string, "Allow")
    ip_rules = optional(list(object({
      value = string
    })), [])
    virtual_network_rules = optional(list(object({
      id                               = string
      state                           = optional(string)
      ignoreMissingVnetServiceEndpoint = optional(bool)
    })), [])
  })
  default = {
    default_action        = "Allow"
    ip_rules              = []
    virtual_network_rules = []
  }
  description = "Network access control list for the account."
}

variable "public_network_access" {
  type        = string
  default     = null
  description = "Whether public network access is allowed. Values: 'Enabled', 'Disabled'."

  validation {
    condition     = var.public_network_access == null || contains(["Enabled", "Disabled"], var.public_network_access)
    error_message = "The public network access must be either 'Enabled' or 'Disabled'."
  }
}

variable "quota_limit" {
  type = object({
    count         = optional(number)
    renewalPeriod = optional(number)
    rules = optional(list(object({
      key                = string
      matchPatterns      = list(object({
        method = string
        path   = string
      }))
      renewalPeriod      = number
      dynamicThrottlingEnabled = optional(bool)
    })))
  })
  default     = null
  description = "The quota limit configuration for the account."
}

variable "restore" {
  type        = bool
  default     = null
  description = "Whether to restore a soft-deleted account."
}

variable "restrict_outbound_network_access" {
  type        = bool
  default     = null
  description = "Whether to restrict outbound network access."
}

variable "user_owned_storage" {
  type = list(object({
    resourceId           = string
    identityClientId     = optional(string)
    revisionId           = optional(string)
    subdomainName        = optional(string)
  }))
  default     = []
  description = "The user-owned storage accounts for the account."
}

variable "allow_project_management" {
  type        = bool
  default     = true
  description = "Whether to allow project management for AI Foundry."
}

variable "network_injections" {
  type = list(object({
    scenario                   = string
    subnetArmId               = string
    useMicrosoftManagedNetwork = optional(bool, false)
  }))
  default     = []
  description = "Network injection configurations for the account."
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
