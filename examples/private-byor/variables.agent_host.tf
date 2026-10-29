variable "create_account_capability_host" {
  type        = bool
  default     = false
  nullable    = false
  description = "Opt into explicit account capability host provisioning only after confirming the injected account has no existing or provisioning host. False preserves platform ownership. Enable for the absent-host provisioning regression."
}
