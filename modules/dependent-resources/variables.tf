variable "ai_search_name" {
  type        = string
  description = "AI search name"
}

variable "cosmos_db_name" {
  type        = string
  description = "Cosmos DB name"
}

variable "key_vault_name" {
  type        = string
  description = "Key vault name"
}

variable "location" {
  type        = string
  description = "Azure region"
  nullable    = false
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

variable "create_dependent_resources" {
  type        = bool
  default     = true
  description = "Whether to create dependent resources like AI Search, Cosmos DB, Key Vault, and Storage Account. If set to false, these resources will not be created, and the module will only create the AI Foundry account."
}

variable "create_private_endpoints" {
  type        = bool
  default     = true
  description = "Whether to create private endpoints for AI Foundry, Cosmos DB, Key Vault, and AI Search. If set to false, private endpoints will not be created, and the resources will be accessible over public endpoints. This is useful for scenarios where private connectivity is not required or when using existing resources that do not require private endpoints."
}

variable "private_dns_zone_resource_id_cosmosdb" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of the private DNS zone for Cosmos DB."
}

variable "private_dns_zone_resource_id_keyvault" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of the private DNS zone for Key Vault."
}

variable "private_dns_zone_resource_id_search" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of the private DNS zone for AI Search."
}

variable "private_dns_zone_resource_id_storage_blob" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of the private DNS zone for Storage Blob."
}

variable "private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "(Optional) The subnet ID for private endpoints."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to resources"
}
