# variable "ai_services_id" {
#   type        = string
#   description = "Resource ID of the AI services multi-services account"
# }

variable "ai_agent_host_name" {
  type        = string
  description = "Name of the AI agent capability host"
}

variable "ai_foundry_id" {
  type        = string
  description = "Resource ID of the AI Foundry account"
}

variable "ai_foundry_project_description" {
  type        = string
  description = "Description for the AI Foundry project"
}

variable "ai_foundry_project_display_name" {
  type        = string
  description = "Display name for the AI Foundry project"
}

variable "ai_foundry_project_name" {
  type        = string
  description = "Name of the AI Foundry project"
}

variable "ai_search_id" {
  type        = string
  description = "Resource ID of the AI Search service"
}

variable "ai_search_name" {
  type        = string
  description = "Name of the AI Search service"
}

variable "cosmos_db_id" {
  type        = string
  description = "Resource ID of the Cosmos DB account"
}

variable "cosmos_db_name" {
  type        = string
  description = "Name of the Cosmos DB account"
}

variable "deploy_ai_search" {
  type        = bool
  description = "Whether AI Search is being deployed (not BYO)"
}

variable "deploy_cosmos_db" {
  type        = bool
  description = "Whether Cosmos DB is being deployed (not BYO)"
}

variable "deploy_storage_account" {
  type        = bool
  description = "Whether Storage Account is being deployed (not BYO)"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "storage_account_id" {
  type        = string
  description = "Resource ID of the Storage Account"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the Storage Account"
}

variable "agent_subnet_resource_id" {
  type        = string
  default     = null
  description = "Subnet resource ID for the AI agent service"
}

variable "create_ai_agent_service" {
  type        = bool
  default     = true
  description = "Whether to create the AI agent service"
}

variable "create_ai_foundry_project" {
  type        = bool
  default     = true
  description = "Whether to create the AI Foundry project"
}

variable "storage_connections" {
  type        = list(string)
  default     = []
  description = "Storage connections for the agent service"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources"
}

variable "thread_storage_connections" {
  type        = list(string)
  default     = []
  description = "Thread storage connections for the agent service"
}

variable "vector_store_connections" {
  type        = list(string)
  default     = []
  description = "Vector store connections for the agent service"
}
