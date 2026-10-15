output "local_authentication_disabled" {
  value       = module.cosmosdb.local_authentication_disabled
  description = "Whether the SQL API account disables local authentication."
}
