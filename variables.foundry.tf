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
    private_dns_zone_resource_id = optional(string, null)
    sku                          = optional(string, "S0")
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
  - `subnetArmId` - (Optional) The subnet ID for the AI agent service."
  - `useMicrosoftManagedNetwork` - (Optional) Whether to use Microsoft managed network for the injection. Default is false.
- `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for AI Foundry. If not provided, a private endpoint will not be created.
- `sku` - (Optional) The SKU of the AI Foundry service. Default is "S0".
DESCRIPTION
}
