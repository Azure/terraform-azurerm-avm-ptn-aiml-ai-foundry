# Module-owned Agent capability host

This opt-in configuration example explicitly enables module ownership of the
**account** Agent capability host for a customer-managed agent network injection.
It calls the existing [private BYOR example](../private-byor) with
`create_account_capability_host = true`; that example passes the setting inside
the Foundry module's `ai_foundry` object. It reuses the same delegated subnet,
BYO Storage, Cosmos DB and Search, project connections, identities, RBAC,
private endpoints and DNS without copying or changing that infrastructure.

The Foundry module selects the unique customer-managed `scenario = "agent"`
injection and sends its `subnetArmId` as the account host's
`properties.customerSubnet` **string**. Existing account-before-project
capability-host dependencies are retained. The output requires both host IDs;
it does not establish service readiness or agent execution.

## Required existing deployment state

Use this example only when the account managed by this same Terraform
deployment has finished provisioning and an operator has verified that it has
**no existing or provisioning account capability host**. Network injection
normally lets Azure provision the account host automatically. This example
does not discover, adopt, import or delete that platform-owned host, and must
not attempt to create a second host. The service permits only one host at each
account or project scope.

This is not a universal fresh-deployment example. A new injected account can
auto-create a host before the explicit host request, causing a conflict. For a
fresh deployment, use `private-byor` with its default platform ownership.
Only enable this path after establishing the absent-host precondition.

The safest way to use the ownership path with an existing `private-byor`
deployment is to keep its original root, backend and Terraform state and set
`create_account_capability_host = true` there. Do **not** switch that state to
this wrapper: the added `module.private_byor` prefix changes resource addresses.
This standalone wrapper is an explicit configuration reference for an
authorized isolated test of the absent-host scenario, not an adoption or
state-migration procedure.

Keep the opt-in enabled after a successful apply. Turning it off plans deletion
of the Terraform-managed account host. Host configuration is immutable; do not
treat a subnet change as a supported in-place host update.

## Running and limitations

After separately authorizing an isolated Azure test scope and verifying the
absent-host precondition, run from this directory using the intended backend
and explicit authenticated tenant/subscription context:

```powershell
terraform init
terraform plan -out=agent-host.tfplan
terraform apply agent-host.tfplan
```

Inspect the saved plan before applying. This example includes a Windows VM,
Bastion, connected services and a subnet-association destroy cooldown; approve
cost and cleanup scope independently. No Azure deployment or cleanup is implied
by the local provider-mocked tests.

The inherited example is **not private-only**: the Foundry private endpoint is
disabled, Search public access and local authentication remain enabled, and
Storage retains its existing access defaults. This example changes no network
policy or identity/CMK configuration. It is not proof of private-only fidelity,
an Azure fresh-deploy test, or a state-backed upgrade test.

`avm test unit` includes the shared BYOR integration wiring and the standalone
wrapper's host-output guards. Mocked tests do not prove Azure ordering or
automatic-host behavior.
