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

variable "private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "(Optional) The subnet ID for private endpoints."
}

variable "private_dns_zone_resource_id_search" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of the private DNS zone for AI Search."
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

variable "private_dns_zone_resource_id_storage_blob" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of the private DNS zone for Storage Blob."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to resources"
}
