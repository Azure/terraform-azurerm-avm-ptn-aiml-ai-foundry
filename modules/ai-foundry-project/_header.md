# Default example

This deploys the module in its simplest form.

## Consumer access to this project

The optional `role_assignments` map creates RBAC assignments on the exact project
resource ID, not on the parent account or dependent services. It defaults to `{}`.
Pass principal object IDs (not application/client IDs), and either role definition
names or fully qualified role definition resource IDs.

```hcl
role_assignments = {
  reader = {
    role_definition_id_or_name = "Reader"
    principal_id               = var.reader_group_object_id
    principal_type             = "Group"
  }
}
```

Names are resolved by the AVM interfaces utility at the project scope. Omit `name`
for a persistent random assignment UUID, or supply a lowercase UUID. Use stable
map keys; use a new key when changing the principal or role. Optional descriptions,
conditions (`condition_version = "2.0"`), delegated managed identity resource IDs,
and principal types are forwarded to ARM. The standard
`skip_service_principal_aad_check` field is accepted for compatibility but has no
effect with AzAPI, which does not look up Entra principals. Supply
`principal_type = "ServicePrincipal"` explicitly for managed identities and other
service principals when needed.

The `role_assignments` output summarizes resource IDs, scope, principal IDs, and
resolved role definition IDs. Existing service-identity grants, resource addresses,
and identity defaults are unchanged. Removing a map entry revokes only that grant
on the next apply; no state migration is required.
