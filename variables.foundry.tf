variable "ai_foundry" {
  type = object({
    name                     = optional(string, null)
    disable_local_auth       = optional(bool, false)
    allow_project_management = optional(bool, true)
    create_ai_agent_service  = optional(bool, false)
    network_injections = optional(list(object({
      scenario                   = optional(string, "agent")
      subnetArmId                = string
      useMicrosoftManagedNetwork = optional(bool, false)
    })), null)
    private_dns_zone_resource_ids = optional(list(string), [])
    sku                           = optional(string, "S0")
    public_network_access_enabled = optional(bool, null)
    network_acls = optional(object({
      default_action = optional(string, "Allow")
      bypass         = optional(string, null)
      ip_rules       = optional(list(string), [])
      virtual_network_rules = optional(list(object({
        subnet_resource_id                   = string
        ignore_missing_vnet_service_endpoint = optional(bool, false)
      })), [])
    }), null)
    managed_identities = optional(object({
      system_assigned            = optional(bool, true)
      user_assigned_resource_ids = optional(set(string), [])
    }), { system_assigned = true, user_assigned_resource_ids = [] })
    customer_managed_key = optional(object({
      key_vault_resource_id              = string
      key_name                           = string
      key_version                        = optional(string, null)
      user_assigned_identity_resource_id = string
    }), null)
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
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure AI Foundry service to be created for AI workloads and model management.

- `name` - (Optional) The name of the AI Foundry service. If not provided, a name will be generated.
- `disable_local_auth` - (Optional) Whether to disable local authentication for the AI Foundry service. Default is false.
- `allow_project_management` - (Optional) Whether to allow project management capabilities in the AI Foundry service. Default is true.
- `create_ai_agent_service` - (Optional) Whether to create an AI agent service as part of the AI Foundry deployment. Default is false.
- `network_injections` - (Optional) List of network injection configurations for the AI Foundry service.
  - `scenario` - (Optional) The scenario for the network injection. Default is "agent".
  - `subnetArmId` - The subnet ARM ID for the AI agent service.
  - `useMicrosoftManagedNetwork` - (Optional) Whether to use Microsoft managed network for the injection. Default is false.
- `private_dns_zone_resource_ids` - (Optional) The resource IDs of the existing private DNS zones for AI Foundry. Required when `create_private_endpoints` is true and `private_endpoint.unmanaged_dns_zone_group_enabled` is false.
- `sku` - (Optional) The SKU of the AI Foundry service. Default is "S0".
- `public_network_access_enabled` - (Optional) Override the public network access setting on the Foundry account. When null (default), the value is derived from `create_private_endpoints` (`false` when private endpoints are enabled, `true` otherwise). Set to `true` or `false` to override.
- `network_acls` - (Optional) Network ACLs applied to the Foundry account. When null (default), the account allows traffic from all networks. Set to restrict traffic when running in production landing zones.
  - `default_action` - (Optional) `Allow` or `Deny`. Default `Allow`.
  - `bypass` - (Optional) Bypass rule for trusted Azure services. Use `AzureServices` to permit Microsoft services to bypass the rules.
  - `ip_rules` - (Optional) List of CIDR ranges or IPv4 addresses allowed inbound access.
  - `virtual_network_rules` - (Optional) List of subnet objects allowed inbound access. Each entry requires `subnet_resource_id` and optionally `ignore_missing_vnet_service_endpoint`.
- `private_endpoint` - (Optional) Override block for the AI Foundry account private endpoint. All fields are optional and fall back to the root-level `private_endpoint_subnet_resource_id`, `resource_group_resource_id`, `location`, and the top-level `private_dns_zone_resource_ids` when null. Used when the Foundry account PE must live in a different resource group, region, subnet, or use unmanaged DNS.
  - `resource_group_resource_id` - (Optional) Resource ID of the resource group hosting the private endpoint. Defaults to the module's resource group.
  - `location` - (Optional) Azure region for the private endpoint. Defaults to the module's location.
  - `subnet_resource_id` - (Optional) Subnet resource ID for the private endpoint NIC. Defaults to `private_endpoint_subnet_resource_id`.
  - `private_dns_zone_resource_ids` - (Optional) Override list of private DNS zone resource IDs. Defaults to `ai_foundry.private_dns_zone_resource_ids`.
  - `unmanaged_dns_zone_group_enabled` - (Optional) When true, no `private_dns_zone_group` is created on the private endpoint. Use this when DNS A records are produced by an Azure Policy (DINE/Modify) on the platform DNS zones in a hub subscription. Default false.
- `managed_identities` - (Optional) Identity configuration for the AI Foundry account.
  - `system_assigned` - (Optional) Enable the system-assigned managed identity. Default true.
  - `user_assigned_resource_ids` - (Optional) Set of user-assigned managed identity resource IDs to attach to the account. When the Foundry account also creates an AI Agent service, every user-assigned identity is granted the Cosmos DB and Storage data-plane roles required by the Standard Agent Setup.
- `customer_managed_key` - (Optional) Customer-managed key encryption configuration. Requires a Key Vault with an existing key and a user-assigned managed identity with "Key Vault Crypto User" role on the Key Vault.
  - `key_vault_resource_id` - Resource ID of the Key Vault containing the encryption key.
  - `key_name` - Name of the Key Vault key to use for encryption.
  - `key_version` - (Optional) Version of the Key Vault key. If not specified, uses the latest version.
  - `user_assigned_identity_resource_id` - Resource ID of the user-assigned managed identity with access to the Key Vault.
- `role_assignments` - (Optional) Map of role assignments to create on the AI Foundry service. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `role_definition_id_or_name` - The role definition ID or name to assign.
  - `principal_id` - The principal ID to assign the role to.
  - `description` - (Optional) Description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
  - `condition` - (Optional) Condition for the role assignment.
  - `condition_version` - (Optional) Version of the condition.
  - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
  - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
DESCRIPTION
}

variable "cognitive_services_api_version" {
  type        = string
  default     = "2025-10-01-preview"
  description = "API version used for Microsoft.CognitiveServices account resources. Use `2025-07-01-preview` for compatibility with AzAPI provider versions that do not include `2025-10-01-preview`."

  validation {
    condition = contains([
      "2025-07-01-preview",
      "2025-10-01-preview"
    ], var.cognitive_services_api_version)
    error_message = "Allowed values for cognitive_services_api_version are 2025-07-01-preview and 2025-10-01-preview."
  }
}
