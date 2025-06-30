module "everything" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
  suffix                 = ["standard", "public"]
  unique-length          = 5
  unique-include-numbers = false
}

output "sa" {
  value = module.everything.storage_account.name_unique
}

output "rg" {
  value = module.everything.resource_group.name_unique
}

output "cognitive_account" {
  value = module.everything.cognitive_account.name_unique
}
