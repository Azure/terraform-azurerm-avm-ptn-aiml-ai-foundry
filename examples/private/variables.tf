variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "The Azure region for this module's resources or telemetry deployment."
  nullable    = false
}

variable "virtual_machine_sku_size" {
  type        = string
  default     = "Standard_D4s_v6"
  description = "SKU size for the Windows test virtual machine. Override with a size available in the selected region and zone that supports the Generation 2 image."
  nullable    = false

  validation {
    condition     = length(trimspace(var.virtual_machine_sku_size)) > 0
    error_message = "The virtual machine SKU size must not be empty."
  }
}
