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

variable "agent_subnet_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of an existing subnet for AI agent services (Container Apps). Optional - only needed when deploying agent services."

  validation {
    condition     = var.agent_subnet_resource_id == null || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.agent_subnet_resource_id))
    error_message = "The agent_subnet_resource_id must be a valid Azure Subnet resource ID."
  }
}

variable "ai_foundry_private_endpoints" {
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
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
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
  description = "Private endpoint configuration for the AI Services account."
  nullable    = false
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

variable "ai_search_private_endpoints" {
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
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
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
  description = "Private endpoint configuration for the AI Search service."
  nullable    = false
}

variable "cosmos_db_private_endpoints" {
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
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
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
  description = "Private endpoint configuration for the Cosmos DB account."
  nullable    = false
}

variable "create_ai_agent_service" {
  type        = bool
  default     = true
  description = "Whether to create an AI agent service using AzAPI capability hosts."
}

variable "create_ai_foundry_project" {
  type        = bool
  default     = true
  description = "Whether to create an AI Foundry project workspace."
}

variable "create_resource_group" {
  type        = bool
  default     = true
  description = "Whether to create a new resource group. Set to false to use an existing resource group specified in resource_group_name."
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

variable "existing_ai_search_resource_id" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of an existing AI Search service to use. If not provided, a new AI Search service will be created."
}

variable "existing_ai_services_resource_id" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of an existing AI Services multi-service account (Microsoft.CognitiveServices/accounts with kind 'CognitiveServices') to use for AI agent capabilities. If not provided, the AI Foundry account will be used."

  validation {
    condition     = var.existing_ai_services_resource_id == null || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.CognitiveServices/accounts/[^/]+$", var.existing_ai_services_resource_id))
    error_message = "The existing_ai_services_resource_id must be a valid Azure Cognitive Services account resource ID."
  }
}

variable "existing_cosmos_db_resource_id" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of an existing Cosmos DB account to use. If not provided, a new Cosmos DB account will be created."
}

variable "existing_key_vault_resource_id" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of an existing Key Vault to use. If not provided, a new Key Vault will be created."
}

variable "existing_log_analytics_workspace_resource_id" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of an existing Log Analytics Workspace to use. If not provided, a new Log Analytics Workspace will be created."
}

variable "existing_storage_account_resource_id" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of an existing storage account to use. If not provided, a new storage account will be created."
}

variable "key_vault_private_endpoints" {
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
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
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
  description = "Private endpoint configuration for the Key Vault."
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
    ai_search                       = optional(string)
    cosmos_db                       = optional(string)
    key_vault                       = optional(string)
    resource_group                  = optional(string)
    storage_account                 = optional(string)
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

variable "storage_private_endpoints" {
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
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
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
  description = "Private endpoint configuration for the Storage Account."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags to be applied to all resources."
}
