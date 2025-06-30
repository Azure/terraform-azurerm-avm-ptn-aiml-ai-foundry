variable "ai_search_name" {
  type        = string
  description = "AI search name"
}

variable "cosmos_db_name" {
  type        = string
  description = "Cosmos DB name"
}

variable "deploy_ai_search" {
  type        = bool
  description = "Whether to deploy AI search"
}

variable "deploy_cosmos_db" {
  type        = bool
  description = "Whether to deploy cosmos DB"
}

variable "deploy_key_vault" {
  type        = bool
  description = "Whether to deploy key vault"
}

variable "deploy_storage_account" {
  type        = bool
  description = "Whether to deploy storage account"
}

variable "key_vault_name" {
  type        = string
  description = "Key vault name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "ai_search_private_endpoints" {
  type = map(object({
    name                            = optional(string, null)
    subnet_resource_id              = string
    subresource_name                = string
    private_dns_zone_resource_ids   = optional(set(string), [])
    private_dns_zone_group_name     = optional(string, "default")
    private_service_connection_name = optional(string, null)
    network_interface_name          = optional(string, null)
    location                        = optional(string, null)
    resource_group_name             = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
    tags = optional(map(string), null)
  }))
  default     = {}
  description = "Private endpoint configuration for AI search"
}

variable "cosmos_db_private_endpoints" {
  type = map(object({
    name                            = optional(string, null)
    subnet_resource_id              = string
    subresource_name                = string
    private_dns_zone_resource_ids   = optional(set(string), [])
    private_dns_zone_group_name     = optional(string, "default")
    private_service_connection_name = optional(string, null)
    network_interface_name          = optional(string, null)
    location                        = optional(string, null)
    resource_group_name             = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
    tags = optional(map(string), null)
  }))
  default     = {}
  description = "Private endpoint configuration for cosmos DB"
}

variable "key_vault_private_endpoints" {
  type = map(object({
    name                            = optional(string, null)
    subnet_resource_id              = string
    subresource_name                = string
    private_dns_zone_resource_ids   = optional(set(string), [])
    private_dns_zone_group_name     = optional(string, "default")
    private_service_connection_name = optional(string, null)
    network_interface_name          = optional(string, null)
    location                        = optional(string, null)
    resource_group_name             = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
    tags = optional(map(string), null)
  }))
  default     = {}
  description = "Private endpoint configuration for key vault"
}

variable "storage_private_endpoints" {
  type = map(object({
    name                            = optional(string, null)
    subnet_resource_id              = string
    subresource_name                = string
    private_dns_zone_resource_ids   = optional(set(string), [])
    private_dns_zone_group_name     = optional(string, "default")
    private_service_connection_name = optional(string, null)
    network_interface_name          = optional(string, null)
    location                        = optional(string, null)
    resource_group_name             = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
    tags = optional(map(string), null)
  }))
  default     = {}
  description = "Private endpoint configuration for storage account"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources"
}
