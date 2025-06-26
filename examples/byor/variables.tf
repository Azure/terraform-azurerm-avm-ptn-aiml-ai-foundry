variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "resource_group_name" {
  type        = string
  description = "The name of an existing resource group to deploy resources into."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be deployed."
}
