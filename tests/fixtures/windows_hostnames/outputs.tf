output "computer_names" {
  description = "Windows guest computer names for the private examples."
  value       = { for example, naming in module.naming : example => naming.names.virtual_machine_windows.name_unique }
}

output "example_suffixes" {
  description = "Actual naming suffixes used by the Windows VM examples."
  value       = local.example_suffixes
}

output "resource_names" {
  description = "Azure VM resource names, independently of the Windows hostname limit."
  value       = { for example, naming in module.naming : example => naming.names.compute_virtual_machine.name_unique }
}
