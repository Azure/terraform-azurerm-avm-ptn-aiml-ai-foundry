variable "ai_projects" {
  type = map(object({
    name                       = string
    sku                        = optional(string, "S0")
    display_name               = string
    description                = string
    create_project_connections = optional(bool, false)
    role_assignments = optional(map(object({
      name                                   = optional(string, null)
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    managed_identities = optional(object({
      system_assigned            = optional(bool, true)
      user_assigned_resource_ids = optional(set(string), [])
    }), { system_assigned = true })
    cosmos_db_connection = optional(object({
      existing_resource_id = optional(string, null)
      new_resource_map_key = optional(string, null)
    }), {})
    ai_search_connection = optional(object({
      existing_resource_id = optional(string, null)
      new_resource_map_key = optional(string, null)
    }), {})
    key_vault_connection = optional(object({
      existing_resource_id = optional(string, null)
      new_resource_map_key = optional(string, null)
    }), {})
    storage_account_connection = optional(object({
      existing_resource_id = optional(string, null)
      new_resource_map_key = optional(string, null)
    }), {})
  }))
  default     = {}
  description = <<DESCRIPTION
Configuration map for AI Foundry projects to be created. Each project can have its own settings and connections to dependent resources.

- `map key` - The key for the map entry. This key should match the dependent resources keys when creating connections.
  - `name` - The name of the AI Foundry project.
  - `sku` - (Optional) The SKU of the AI Foundry project. Default is "S0".
  - `display_name` - The display name of the AI Foundry project.
  - `description` - The description of the AI Foundry project.
  - `create_project_connections` - (Optional) Whether to create connections to dependent resources. Default is false.
  - `role_assignments` - (Optional) Map of role assignments scoped to this project; defaults to `{}`. Uses the same fields as the root `role_assignments` input: optional UUID `name`, required `role_definition_id_or_name` and `principal_id`, and optional `description`, `skip_service_principal_aad_check`, `condition`, `condition_version`, `delegated_managed_identity_resource_id`, and `principal_type`. Use stable, arbitrary map keys and principal object IDs, not application/client IDs.
  - `managed_identities` - (Optional) Identity configuration for the project. The system-assigned identity defaults to enabled to preserve existing behavior.
    - `system_assigned` - (Optional) Whether to enable the system-assigned identity. Defaults to true; set explicitly to false for a UAMI-only project.
    - `user_assigned_resource_ids` - (Optional) Set of user-assigned managed identity resource IDs to attach to the project.
  - `cosmos_db_connection` - (Optional) Configuration for Cosmos DB connection.
    - `existing_resource_id` - (Optional) The resource ID of an existing Cosmos DB account to connect to.
    - `new_resource_map_key` - (Optional) The map key of a new Cosmos DB account to be created and connected.
  - `ai_search_connection` - (Optional) Configuration for AI Search connection.
    - `existing_resource_id` - (Optional) The resource ID of an existing AI Search service to connect to.
    - `new_resource_map_key` - (Optional) The map key of a new AI Search service to be created and connected.
  - `key_vault_connection` - (Optional) Configuration for Key Vault connection.
    - `existing_resource_id` - (Optional) The resource ID of an existing Key Vault to connect to.
    - `new_resource_map_key` - (Optional) The map key of a new Key Vault to be created and connected.
  - `storage_account_connection` - (Optional) Configuration for Storage Account connection.
    - `existing_resource_id` - (Optional) The resource ID of an existing Storage Account to connect to.
    - `new_resource_map_key` - (Optional) The map key of a new Storage Account to be created and connected.
DESCRIPTION

  validation {
    condition = alltrue(flatten([
      for project in values(var.ai_projects) : [
        for id in project.managed_identities.user_assigned_resource_ids :
        can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", id))
      ]
    ]))
    error_message = "Each project managed identity must be a valid user-assigned identity resource ID."
  }
  validation {
    condition = alltrue([
      for project in values(var.ai_projects) :
      !project.create_project_connections || project.managed_identities.system_assigned || length(project.managed_identities.user_assigned_resource_ids) > 0
    ])
    error_message = "Project connections require a system-assigned identity or at least one user-assigned identity."
  }
}
