module "naming" {
  source   = "Azure/avm-utl-naming/azure"
  version  = "0.2.0"
  for_each = local.example_suffixes

  suffix        = [each.value]
  unique-length = 5
  unique_seed   = "bej2j"
}
