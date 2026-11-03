module "private_byor" {
  source = "../private-byor"

  create_account_capability_host = true
  enable_telemetry               = var.enable_telemetry
  location                       = var.location
  virtual_machine_sku_size       = var.virtual_machine_sku_size
}
