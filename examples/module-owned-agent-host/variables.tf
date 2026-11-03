variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Whether to enable telemetry in the reused private BYOR deployment."
  nullable    = false
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "The Azure region for the reused private BYOR deployment."
  nullable    = false
}

variable "virtual_machine_sku_size" {
  type        = string
  default     = "Standard_D4s_v6"
  description = "SKU size for the Windows test virtual machine in the reused private BYOR deployment."
  nullable    = false
}
