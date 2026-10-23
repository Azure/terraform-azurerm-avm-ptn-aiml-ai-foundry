###############################################################################
# Platform / subscription context
###############################################################################

variable "subscription_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Resource ID (GUID) of the application landing zone subscription that will host the
AI Foundry workload. Leave null to fall back to ARM_SUBSCRIPTION_ID / az CLI context.
DESCRIPTION
}

variable "location" {
  type        = string
  description = "Azure region for the workload. Must be a region where AI Foundry, the chosen models and your ALZ spoke all exist."

  # Private VNet support for the Foundry Agent Service is only available in a
  # subset of regions, and an unsupported region is not rejected until the agent
  # service fails partway through apply. Source:
  # https://learn.microsoft.com/azure/ai-foundry/agents/concepts/limits-quotas-regions
  validation {
    condition = contains([
      "australiaeast", "brazilsouth", "canadacentral", "canadaeast", "centralus",
      "eastus", "eastus2", "francecentral", "germanywestcentral", "italynorth",
      "japaneast", "japanwest", "koreacentral", "northcentralus", "norwayeast",
      "polandcentral", "southafricanorth", "southcentralus", "southeastasia",
      "southindia", "spaincentral", "swedencentral", "switzerlandnorth",
      "switzerlandwest", "uaenorth", "uksouth", "westcentralus", "westeurope",
      "westus", "westus3",
    ], lower(replace(var.location, " ", "")))
    error_message = "location must be a region where the Foundry Agent Service supports private VNet injection. Note that westus2 is not supported. See https://learn.microsoft.com/azure/ai-foundry/agents/concepts/limits-quotas-regions."
  }
}

variable "base_name" {
  type        = string
  description = "Short workload name used to build resource names (lowercase alphanumeric and dashes, keep it under 12 characters)."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,11}$", var.base_name))
    error_message = "base_name must be 2-12 characters, lowercase alphanumeric or dash, and start with a letter or digit."
  }
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment short code appended to generated resource names (for example dev, test, prod)."

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.environment))
    error_message = "environment must be 2-6 lowercase alphanumeric characters."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to every resource created by this configuration. Merge your ALZ mandatory tag set in here."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Controls the Azure Verified Modules telemetry deployment. Set to false if your ALZ policy blocks it."
}

###############################################################################
# Resource group
###############################################################################

variable "resource_group" {
  type = object({
    create = optional(bool, true)
    name   = optional(string, null)
  })
  default     = {}
  description = <<DESCRIPTION
Resource group that hosts the AI Foundry workload inside the application landing zone.

- `create` - (Optional) Create the resource group. Set to false when the platform team pre-creates it. Default `true`.
- `name`   - (Optional) Resource group name. Required when `create = false`; otherwise a name is generated.
DESCRIPTION

  validation {
    condition     = var.resource_group.create || try(length(var.resource_group.name) > 0, false)
    error_message = "resource_group.name is required when resource_group.create is false."
  }
}

###############################################################################
# Existing landing zone networking
###############################################################################

variable "private_endpoint_subnet_resource_id" {
  type        = string
  description = <<DESCRIPTION
Resource ID of the EXISTING subnet in the ALZ spoke that hosts private endpoints.
Example: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/snet-privateendpoints
DESCRIPTION

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.private_endpoint_subnet_resource_id))
    error_message = "private_endpoint_subnet_resource_id must be a fully qualified subnet resource ID."
  }
}

variable "agent_subnet" {
  type = object({
    resource_id                         = optional(string, null)
    create                              = optional(bool, false)
    name                                = optional(string, "snet-ai-agents")
    address_prefixes                    = optional(list(string), null)
    virtual_network_name                = optional(string, null)
    virtual_network_resource_group_name = optional(string, null)
  })
  default     = {}
  description = <<DESCRIPTION
Subnet used for AI Foundry Standard Agent network injection. The subnet must be delegated to
`Microsoft.App/environments` and must not be shared with any other workload.

- `resource_id` - (Optional) Resource ID of an EXISTING delegated subnet. Preferred when the platform team owns the spoke.
- `create`      - (Optional) Create the delegated subnet inside an existing spoke VNet. Default `false`.
- `name`        - (Optional) Name of the subnet to create. Default `snet-ai-agents`.
- `address_prefixes` - (Optional) CIDR list for the subnet to create. A /24 is recommended.
- `virtual_network_name` / `virtual_network_resource_group_name` - (Optional) Existing spoke VNet to create the subnet in.
DESCRIPTION

  validation {
    condition = (
      (var.agent_subnet.resource_id != null && !var.agent_subnet.create) ||
      (var.agent_subnet.create &&
        var.agent_subnet.address_prefixes != null &&
        var.agent_subnet.virtual_network_name != null &&
      var.agent_subnet.virtual_network_resource_group_name != null)
    )
    error_message = "Provide agent_subnet.resource_id for an existing subnet, or set create = true together with address_prefixes, virtual_network_name and virtual_network_resource_group_name."
  }
}

###############################################################################
# Existing landing zone private DNS
###############################################################################

variable "manage_private_dns_zone_groups" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
Whether this configuration attaches private DNS zone groups to the private endpoints it creates.

Set to `false` when your platform uses an Azure Policy DeployIfNotExists / Modify assignment to
register private endpoint A records against the hub private DNS zones. In that case no zone IDs
are required and the DNS zone group is left entirely to policy.
DESCRIPTION

  validation {
    condition = !var.manage_private_dns_zone_groups || (
      var.create_private_dns_zones ||
      var.private_dns_zone_resource_group_id != null ||
      length(var.private_dns_zone_resource_ids) >= 7
    )
    error_message = "When manage_private_dns_zone_groups is true you must either set create_private_dns_zones = true, supply private_dns_zone_resource_group_id, or give an explicit ID for all seven zones in private_dns_zone_resource_ids."
  }
}

variable "create_private_dns_zones" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
Create the seven private DNS zones this workload needs, in the workload resource group, instead of
consuming zones the platform already owns.

Leave this `false` for a real enterprise-scale landing zone: private DNS is a platform concern and
duplicating the zones in a spoke causes split-brain resolution. Set it to `true` only for a sandbox
or greenfield subscription that has no hub, no zone delegation and no DNS policy.

When `true`, supply `private_dns_zone_virtual_network_resource_ids` so the zones are linked to the
virtual networks that need to resolve the private endpoints.
DESCRIPTION

  validation {
    condition     = !var.create_private_dns_zones || length(var.private_dns_zone_virtual_network_resource_ids) > 0
    error_message = "When create_private_dns_zones is true you must link at least one virtual network via private_dns_zone_virtual_network_resource_ids, otherwise nothing can resolve the private endpoints."
  }
}

variable "private_dns_zone_virtual_network_resource_ids" {
  type        = map(string)
  default     = {}
  description = <<DESCRIPTION
Virtual networks to link the created private DNS zones to. Only used when
`create_private_dns_zones` is `true`.

The map key is a short, stable link name; the value is the virtual network resource ID. Include
every VNet whose clients must resolve the private endpoints, for example the spoke itself plus any
VNet hosting a jump box.

```hcl
private_dns_zone_virtual_network_resource_ids = {
  spoke = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>"
}
```
DESCRIPTION

  validation {
    condition = alltrue([
      for id in values(var.private_dns_zone_virtual_network_resource_ids) :
      can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", id))
    ])
    error_message = "Each value in private_dns_zone_virtual_network_resource_ids must be a fully qualified virtual network resource ID."
  }

  validation {
    condition = alltrue([
      for k in keys(var.private_dns_zone_virtual_network_resource_ids) :
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,48}[a-zA-Z0-9]$", k))
    ])
    error_message = "Keys in private_dns_zone_virtual_network_resource_ids are used as link names and must be 2-50 characters of letters, digits, dot, dash or underscore."
  }
}

variable "private_dns_zone_resource_group_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Resource ID of the EXISTING resource group (usually in the platform connectivity subscription)
that holds the standard Azure private DNS zones. Zone resource IDs are derived from this value
using the well-known zone names, so you only need to supply overrides for non-standard setups.

Example: /subscriptions/<connectivity-sub>/resourceGroups/rg-platform-dns
DESCRIPTION

  validation {
    condition     = var.private_dns_zone_resource_group_id == null || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+$", var.private_dns_zone_resource_group_id))
    error_message = "private_dns_zone_resource_group_id must be a resource group resource ID with no trailing segments."
  }
}

variable "private_dns_zone_resource_ids" {
  type        = map(string)
  default     = {}
  description = <<DESCRIPTION
Explicit private DNS zone resource IDs, keyed by zone purpose. Any key supplied here overrides the
value derived from `private_dns_zone_resource_group_id`.

Supported keys and the zones they map to:
- `openai`            -> privatelink.openai.azure.com
- `cognitiveservices` -> privatelink.cognitiveservices.azure.com
- `ai_services`       -> privatelink.services.ai.azure.com
- `blob`              -> privatelink.blob.core.windows.net
- `vault`             -> privatelink.vaultcore.azure.net
- `cosmos_sql`        -> privatelink.documents.azure.com
- `search`            -> privatelink.search.windows.net
- `video_indexer`     -> privatelink.api.videoindexer.ai (only when deploy_video_indexer = true)
DESCRIPTION

  validation {
    condition = alltrue([
      for k in keys(var.private_dns_zone_resource_ids) :
      contains(["openai", "cognitiveservices", "ai_services", "blob", "vault", "cosmos_sql", "search", "video_indexer"], k)
    ])
    error_message = "private_dns_zone_resource_ids may only use the keys openai, cognitiveservices, ai_services, blob, vault, cosmos_sql, search and video_indexer."
  }
}

###############################################################################
# Observability
###############################################################################

variable "log_analytics_workspace_resource_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Resource ID of the EXISTING Log Analytics workspace (normally the ALZ management subscription
workspace) that receives diagnostic settings. Set to null to skip diagnostic settings, for example
when a platform DINE policy already assigns them.
DESCRIPTION
}

###############################################################################
# Dependent (BYOR) data services
###############################################################################

variable "resource_names" {
  type = object({
    ai_foundry      = optional(string, null)
    key_vault       = optional(string, null)
    storage_account = optional(string, null)
    cosmosdb        = optional(string, null)
    ai_search       = optional(string, null)

    video_indexer                 = optional(string, null)
    video_indexer_storage_account = optional(string, null)
  })
  default     = {}
  description = "Explicit resource names that override the generated names. Use this to comply with your enterprise naming standard."
}

variable "storage_account" {
  type = object({
    account_replication_type = optional(string, "ZRS")
    account_tier             = optional(string, "Standard")
    account_kind             = optional(string, "StorageV2")
    access_tier              = optional(string, "Hot")
  })
  default     = {}
  description = "Overrides for the BYOR storage account that backs AI Foundry agent file storage."
}

variable "cosmosdb" {
  type = object({
    consistency_level       = optional(string, "Session")
    max_interval_in_seconds = optional(number, 300)
    max_staleness_prefix    = optional(number, 100001)
    automatic_failover      = optional(bool, true)
    zone_redundant          = optional(bool, true)
    secondary_regions = optional(list(object({
      location          = string
      zone_redundant    = optional(bool, false)
      failover_priority = optional(number, 1)
    })), [])
  })
  default     = {}
  description = "Overrides for the BYOR Cosmos DB account that backs AI Foundry agent thread storage."
}

variable "ai_search" {
  type = object({
    sku                          = optional(string, "standard")
    replica_count                = optional(number, 2)
    partition_count              = optional(number, 1)
    semantic_search              = optional(string, "disabled")
    local_authentication_enabled = optional(bool, false)
    location                     = optional(string, null)
  })
  default     = {}
  description = <<DESCRIPTION
Overrides for the BYOR Azure AI Search service that backs AI Foundry vector stores.

- `location` - (Optional) Deploy AI Search in a different region from the rest of the workload.
  Defaults to `var.location`. AI Foundry supports its dependent data services in another region,
  which is the escape hatch when the Foundry region has no AI Search capacity
  (`InsufficientResourcesAvailable`). The private endpoint still lives in the workload VNet, so
  resolution is unchanged, but cross-region queries add latency and egress cost.
DESCRIPTION

  validation {
    condition     = contains(["disabled", "free", "standard"], var.ai_search.semantic_search)
    error_message = "ai_search.semantic_search must be one of disabled, free or standard."
  }
}

variable "deploy_key_vault" {
  type        = bool
  default     = true
  description = "Deploy a Key Vault alongside the workload for Foundry connection secrets and future customer-managed keys."
}

###############################################################################
# Azure AI Video Indexer (optional)
###############################################################################

variable "deploy_video_indexer" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
Deploy an Azure AI Video Indexer account for video analysis: scene and shot boundary detection,
keyframes, transcription, OCR of on-screen text, face and object detection, and speaker
diarization. It produces a time-coded index of existing footage, which an agent or model can then
reason over - it does not generate video.

This is OFF by default. It is independent of AI Foundry: nothing else in this configuration
depends on it, and the Foundry deployment works with it disabled.

Enabling it creates a Video Indexer account, a DEDICATED storage account that only it uses, and a
user-assigned managed identity that Video Indexer uses to reach that storage.
DESCRIPTION
}

variable "video_indexer" {
  type = object({
    location                           = optional(string, null)
    storage_account_replication_type   = optional(string, "LRS")
    storage_account_shared_key_enabled = optional(bool, false)
    public_network_access_enabled      = optional(bool, false)
    connect_to_ai_foundry              = optional(bool, false)
  })
  default     = {}
  description = <<DESCRIPTION
Overrides for the optional Azure AI Video Indexer account. Ignored when
`deploy_video_indexer = false`.

- `location` - (Optional) Deploy Video Indexer in a different region from the rest of the
  workload. Defaults to `var.location`. Video Indexer is available in fewer regions than AI
  Foundry, so this is the escape hatch when your Foundry region has no Video Indexer. The
  dedicated storage account follows this region, because Video Indexer requires its storage
  account to be in the same region as the account.

- `storage_account_replication_type` - (Optional) Replication for the dedicated storage account.
  Defaults to `LRS`, because this storage holds re-derivable artefacts rather than the source of
  truth. Use `ZRS` or `GRS` if your landing zone mandates it.

- `storage_account_shared_key_enabled` - (Optional) Defaults to `false`, which is the secure
  posture and uses managed identity. Set to `true` only if you hit an access error that is
  resolved by shared keys - see TROUBLESHOOTING.md.

- `public_network_access_enabled` - (Optional) Defaults to `false` so the account is reachable
  only over its private endpoint, consistent with the rest of this deployment. IMPORTANT: with
  public access disabled the Video Indexer **web app and the Insights/Editor widgets do not
  work** - the account is usable through the REST API only. Set this to `true` if your users need
  the portal experience, and accept that the control plane is then publicly reachable.

- `connect_to_ai_foundry` - (Optional) Wire the Video Indexer account to the AI Foundry account
  created here, so Video Indexer can use it for textual summarization of video content. Defaults
  to `false`. Requires a deployed chat model on the Foundry account; enabling it with no model
  deployment causes summarization calls to fail at runtime.
DESCRIPTION

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS", "RAGRS", "RAGZRS"], var.video_indexer.storage_account_replication_type)
    error_message = "video_indexer.storage_account_replication_type must be one of LRS, ZRS, GRS, GZRS, RAGRS or RAGZRS."
  }
}

###############################################################################
# AI Foundry
###############################################################################

variable "ai_foundry" {
  type = object({
    disable_local_auth       = optional(bool, true)
    allow_project_management = optional(bool, true)
    create_ai_agent_service  = optional(bool, true)
    sku                      = optional(string, "S0")
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
      principal_type             = optional(string, null)
      description                = optional(string, null)
    })), {})
  })
  default     = {}
  description = <<DESCRIPTION
AI Foundry account configuration.

- `disable_local_auth`       - (Optional) Disable API key authentication and force Entra ID. Default `true`.
- `allow_project_management` - (Optional) Allow Foundry projects on the account. Default `true`.
- `create_ai_agent_service`  - (Optional) Enable the Standard Agent setup with VNet injection. Default `true`.
- `sku`                      - (Optional) Account SKU. Default `S0`.
- `role_assignments`         - (Optional) Role assignments created on the Foundry account, for example granting
  `Azure AI Developer` to your workload Entra ID groups.
DESCRIPTION
}

variable "ai_model_deployments" {
  type = map(object({
    name                   = string
    rai_policy_name        = optional(string, "Microsoft.DefaultV2")
    version_upgrade_option = optional(string, "OnceNewDefaultVersionAvailable")
    model = object({
      format  = string
      name    = string
      version = string
    })
    scale = object({
      type     = string
      capacity = optional(number)
      family   = optional(string)
      size     = optional(string)
      tier     = optional(string)
    })
  }))
  default = {
    gpt-4_1 = {
      name = "gpt-4.1"
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1"
        version = "2025-04-14"
      }
      scale = {
        type     = "GlobalStandard"
        capacity = 10
      }
    }
    text-embedding-3-large = {
      name = "text-embedding-3-large"
      model = {
        format  = "OpenAI"
        name    = "text-embedding-3-large"
        version = "1"
      }
      scale = {
        type     = "GlobalStandard"
        capacity = 10
      }
    }
  }
  description = "Model deployments created on the AI Foundry account. Set to {} to deploy models out of band."
}

variable "ai_projects" {
  type = map(object({
    name         = string
    display_name = string
    description  = string
    sku          = optional(string, "S0")
  }))
  default = {
    project_1 = {
      name         = "project-1"
      display_name = "Project 1"
      description  = "Default AI Foundry project."
    }
  }
  description = <<DESCRIPTION
AI Foundry projects to create. Every project is automatically connected to the BYOR Storage
account, Cosmos DB account and AI Search service, and receives the data-plane role assignments
required by the Standard Agent setup.
DESCRIPTION
}

variable "purge_soft_deleted_foundry_on_destroy" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
When true, `terraform destroy` also purges the soft-deleted Cognitive Services account so the name
can be reused immediately and the subnet service association link is released. Leave false if your
organisation relies on the soft-delete recovery window.
DESCRIPTION
}
