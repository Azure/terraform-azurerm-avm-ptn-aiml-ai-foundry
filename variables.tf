variable "base_name" {
  type        = string
  description = "The name prefix for the AI Foundry resources. Will be used as base_name if base_name is not provided."

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

variable "agent_subnet_id" {
  type        = string
  default     = null
  description = "(Optional) The subnet ID for the AI agent service. If not provided, managed network will be used for the AI agent service. If provided, the AI agent service will be deployed in the specified subnet."
}

variable "ai_foundry_project_description" {
  type        = string
  default     = "AI Foundry project for agent services and AI workloads"
  description = "Description for the AI Foundry project."
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

variable "ai_search_resource_id" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of an existing AI Search service to use. If not provided, a new AI Search service will be created."
}

variable "cosmos_db_resource_id" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of an existing Cosmos DB account to use. If not provided, a new Cosmos DB account will be created."
}

variable "create_ai_agent_service" {
  type        = bool
  default     = false
  description = "Whether to create an AI agent service using AzAPI capability hosts."
}



variable "create_project_connections" {
  type        = bool
  default     = false
  description = "Whether to create connections to the AI Foundry project. If set to true, connections will be created for the dependent AI Foundry resources. If set to false, no connections will be created."
}

variable "create_resource_group" {
  type        = bool
  default     = false
  description = "Whether to create a new resource group. Set to false to use an existing resource group specified in resource_group_name."
}

variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = optional(string, "ai-foundry-cmk")
    key_version           = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Configuration for Customer Managed Key (CMK) encryption for AI Foundry. If not provided, Microsoft managed keys will be used.

- `key_vault_resource_id` - (Required) The resource ID of the Key Vault that contains the key.
- `key_name` - (Optional) The name of the key to use for encryption. Defaults to 'ai-foundry-cmk'.
- `key_version` - (Optional) The version of the key to use for encryption. If not specified, the latest version will be used.
DESCRIPTION
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

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `"CanNotDelete"` and `"ReadOnly"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
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
  - `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
  - `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
  - `tags` - (Optional) A mapping of tags to assign to the private endpoint.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
  - `application_security_group_associations` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
  - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
  - `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
  - `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the AI Foundry Account.
  - `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
    - `name` - The name of the IP configuration.
    - `private_ip_address` - The private IP address of the IP configuration.
  DESCRIPTION
  nullable    = false
}

variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  nullable    = false
}



variable "resource_group_id" {
  type        = string
  default     = null
  description = "The full resource ID of the resource group. When provided, this takes precedence over resource_group_name. Useful for cross-subscription deployments or when the exact resource ID is known. Format: '/subscriptions/{subscription-id}/resourceGroups/{resource-group-name}'"

  validation {
    condition     = var.resource_group_id == null || can(regex("^/subscriptions/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/resourceGroups/.+$", var.resource_group_id))
    error_message = "The resource_group_id must be in the format '/subscriptions/{subscription-id}/resourceGroups/{resource-group-name}' when provided."
  }
}

variable "resource_group_name" {
  type        = string
  default     = null
  description = "The name for the resource group. When create_resource_group=true, this will be the name of the new resource group. When create_resource_group=false, this must be the name of an existing resource group."
}

variable "resource_names" {
  type = object({
    ai_agent_host                   = optional(string)
    ai_foundry                      = optional(string)
    ai_foundry_project              = optional(string)
    ai_foundry_project_display_name = optional(string)
    resource_group                  = optional(string)
  })
  default     = {}
  description = "Custom names for each resource. If not provided, names will be generated using base_name or name."
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.
- `delegated_managed_identity_resource_id` - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.
- `principal_type` - The type of the principal_id. Possible values are `User`, `Group` and `ServicePrincipal`. Changing this forces a new resource to be created. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "storage_account_resource_id" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of an existing storage account to use. If not provided, a new storage account will be created."
}

# AI Foundry account configuration variables
variable "ai_foundry_kind" {
  type        = string
  default     = "AIServices"
  description = "The kind of the Cognitive Services account. For AI Foundry, this should be 'AIServices'."

  validation {
    condition = contains([
      "AIServices", "CognitiveServices", "ComputerVision", "ContentModerator", "Face",
      "FormRecognizer", "ImmersiveReader", "LUIS", "Personalizer", "QnAMaker",
      "SpeechServices", "TextAnalytics", "TextTranslation"
    ], var.ai_foundry_kind)
    error_message = "The kind must be a valid Cognitive Services account kind."
  }
}

variable "ai_foundry_sku_name" {
  type        = string
  default     = "S0"
  description = "The SKU name for the AI Foundry account."

  validation {
    condition = contains([
      "F0", "F1", "S0", "S1", "S2", "S3", "S4", "S5", "S6", "E0"
    ], var.ai_foundry_sku_name)
    error_message = "The SKU name must be a valid Cognitive Services SKU."
  }
}

variable "ai_foundry_identity_type" {
  type        = string
  default     = "SystemAssigned"
  description = "The type of managed identity for the AI Foundry account."

  validation {
    condition = contains([
      "None", "SystemAssigned", "UserAssigned", "SystemAssigned,UserAssigned"
    ], var.ai_foundry_identity_type)
    error_message = "The identity type must be None, SystemAssigned, UserAssigned, or SystemAssigned,UserAssigned."
  }
}

variable "ai_foundry_user_assigned_identity_ids" {
  type        = list(string)
  default     = []
  description = "The list of user assigned identity IDs to assign to the AI Foundry account."
}

variable "ai_foundry_api_properties" {
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
  description = "API-specific properties for the AI Foundry account."
}

variable "ai_foundry_custom_sub_domain_name" {
  type        = string
  default     = null
  description = "The subdomain name used for token-based authentication. When not specified, the AI Foundry account name will be used."
}

variable "ai_foundry_disable_local_auth" {
  type        = bool
  default     = false
  description = "Whether to disable local authentication methods in favor of AAD authentication for the AI Foundry account."
}

variable "ai_foundry_dynamic_throttling_enabled" {
  type        = bool
  default     = null
  description = "Whether to enable dynamic throttling for the AI Foundry account."
}

variable "ai_foundry_fqdn" {
  type        = string
  default     = null
  description = "The fully qualified domain name for the AI Foundry account."
}

variable "ai_foundry_migration_token" {
  type        = string
  default     = null
  description = "The migration token for the AI Foundry account."
}

variable "ai_foundry_network_acls" {
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
  description = "Network access control list for the AI Foundry account."
}

variable "ai_foundry_public_network_access" {
  type        = string
  default     = null
  description = "Whether public network access is allowed for the AI Foundry account. Values: 'Enabled', 'Disabled'."

  validation {
    condition     = var.ai_foundry_public_network_access == null || contains(["Enabled", "Disabled"], var.ai_foundry_public_network_access)
    error_message = "The public network access must be either 'Enabled' or 'Disabled'."
  }
}

variable "ai_foundry_quota_limit" {
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
  description = "The quota limit configuration for the AI Foundry account."
}

variable "ai_foundry_restore" {
  type        = bool
  default     = null
  description = "Whether to restore a soft-deleted AI Foundry account."
}

variable "ai_foundry_restrict_outbound_network_access" {
  type        = bool
  default     = null
  description = "Whether to restrict outbound network access for the AI Foundry account."
}

variable "ai_foundry_user_owned_storage" {
  type = list(object({
    resourceId           = string
    identityClientId     = optional(string)
    revisionId           = optional(string)
    subdomainName        = optional(string)
  }))
  default     = []
  description = "The user-owned storage accounts for the AI Foundry account."
}

variable "ai_foundry_allow_project_management" {
  type        = bool
  default     = true
  description = "Whether to allow project management for AI Foundry."
}

variable "ai_foundry_network_injections" {
  type = list(object({
    scenario                   = string
    subnetArmId               = string
    useMicrosoftManagedNetwork = optional(bool, false)
  }))
  default     = []
  description = "Additional network injection configurations for the AI Foundry account (beyond agent service)."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags to be applied to all resources."
}
