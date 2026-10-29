# Azure AI Foundry Pattern Module

Deploys Azure AI Foundry (account, projects, agent service, connections, RBAC) and lets you either bring your own dependent data services or have the module create them for you. Use **BYOR** for production AI landing zones, **CYOR** for POCs.

## What this module deploys

| Category | Resources | Notes |
| --- | --- | --- |
| **Core** (always deployed) | <ul><li>AI Foundry account</li><li>Projects</li><li>Connections</li><li>RBAC</li><li>Resource locks</li><li>Agent capability host (optional)</li></ul> | Module-owned. |
| **Dependent data services** (BYOR or CYOR) | <ul><li>Key Vault</li><li>Storage Account</li><li>Cosmos DB</li><li>AI Search</li></ul> | Either bring existing IDs (BYOR) or let the module create them (CYOR). See [Production guidance](#production-guidance-byor-vs-cyor). |
| **Networking** (private deployments) | <ul><li>Foundry private endpoint</li><li>VNet, subnets, private DNS (example)</li><li>Bastion, jump VM (example)</li></ul> | Foundry PE is module-owned. VNet / DNS / Bastion / VM live in the examples and in your landing zone. Designed to pair with the [AI Landing Zone Accelerator](https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone). |
| **Observability** | <ul><li>Diagnostic settings</li><li>Log Analytics workspace (example)</li></ul> | Workspace lives in the example / landing zone. |

## Production guidance: BYOR vs CYOR

This module supports two ways of providing the dependent data services (Key Vault, Storage Account, Cosmos DB, AI Search):

| Mode | What it does | Resources you own | Use it for |
| --- | --- | --- | --- |
| **BYOR** (Bring Your Own Resource) | You provision the dependent data services **outside** this module (typically in your landing zone) and pass their IDs in as variables. The module only wires up connections, RBAC, and the Foundry account itself. | <ul><li>Key Vault</li><li>Storage Account</li><li>Cosmos DB</li><li>AI Search</li></ul> | **Production. This is the only supported path for production AI landing zones.** |
| **CYOR** (Create Your Own Resource, the in-module path) | The module provisions the dependent data services for you with opinionated defaults. | <ul><li>Key Vault</li><li>Storage Account</li><li>Cosmos DB</li><li>AI Search</li></ul> (created by the module) | **POC / MVP / demos only.** Fast path to a working Foundry environment when you don't yet have a landing zone. |

### Why BYOR is the production path

- **Lifecycle separation.** Data services typically outlive the Foundry account they back. Owning them outside the pattern module means a `terraform destroy` of the Foundry stack cannot take down a Cosmos DB or Storage account that other workloads depend on.
- **Governance and policy.** In an AI landing zone, Key Vault / Storage / Cosmos / Search are governed by platform teams (naming, encryption, network access, diagnostic settings, DINE/Modify policies, private DNS). Letting this module create them re-introduces drift with those platform controls.
- **Reduced blast radius and dependencies.** BYOR keeps this module focused on what is genuinely Foundry-specific (the account, projects, connections, RBAC, agent capability host) and removes long dependency chains during plan/apply.
- **Shared resources across projects/environments.** Production deployments commonly share one Cosmos DB or one Storage account across multiple Foundry projects or environments. That sharing only works cleanly when those resources live outside any single module instance.
- **Multi-region and cross-region patterns.** PE placement, regional pinning, and cross-region wiring are landing-zone concerns, not module concerns.

### What this means for issues and feature requests

- Feature requests that **only** affect the CYOR path (e.g., exposing additional knobs on the module-created Storage account, Key Vault, Cosmos DB, AI Search, or their private endpoints) will generally **not be accepted**. The recommended fix is to switch to BYOR and configure those properties on your own resources.
- Feature requests that affect the **Foundry account, projects, agent service, connections, RBAC, or the Foundry account's own private endpoint** apply to both modes and are in scope regardless of BYOR/CYOR.
- See the `standard-*-byor` examples for reference BYOR deployments.

## Unit testing

Run `avm test unit` from the repository root.
[`.avm/tool-version-overrides.json`](.avm/tool-version-overrides.json) selects
Terraform `1.17.0` for managed development commands, not only unit tests. The
override is needed for unit tests that mock the Storage dependency's ephemeral
AzAPI action, which the managed default Terraform `1.16.5` cannot mock. It does
not change the module's consumer `required_version` constraint. Remove the
override once the managed default supports these mocks. The override file
accepts only tool/version entries, so this explanation lives here rather than
in a JSON comment.

The root tests exercise the actual
project and Cosmos DB child modules, checking parameter propagation rather than
testing Registry modules in isolation. Coverage includes independent project
role assignments and scopes, empty assignment defaults, and Cosmos DB local
authentication with default, explicitly disabled, and explicitly enabled values.
Azure operations are mocked or overridden; these tests do not deploy resources.
Standalone project tests provide additional identity and ARM body coverage.

## Agent capability hosts with private network injection

When `ai_foundry.create_ai_agent_service = true`, the module creates one
account-level `Agents` capability host, including when
`ai_foundry.network_injections` is configured. Each project with
`create_project_connections = true` also creates its project-level host after
the account host and its BYOR connections. Network injection does not replace
the account-host prerequisite or change which Storage, Cosmos DB, and Search
resources the project uses. The account host ID is returned through
`ai_agent_account_capability_host_id`; it is `null` when agents are disabled.

### Upgrading an existing injected deployment

Release `0.13.0` skipped the account host when network injection was configured.
For that configuration, this fix adds
`azapi_resource.ai_agent_capability_host[0]` inside the module. Existing
non-injected host addresses, generated names, and project-host dependencies are
unchanged. No state move is introduced.

Before applying, inspect both the plan and the account's existing capability
hosts. Azure permits only one active host per account or project scope and
does not support updating its configuration. A host created outside this
module, including during recovery from a partial deployment, needs an
ownership and naming review before applying the planned addition. Do not
blindly import, rename, delete, or create a second host. Removing this fix
after applying it to an injected deployment plans removal of the newly
managed account host and can disrupt dependent agents; a code revert is not
a proven rollback.

See [Capability hosts for Foundry Agent Service](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/capability-hosts)
for service constraints. Provider-mocked regression tests cover injected
agents with BYOR connections, system/user-assigned identities and CMK,
non-injected agents, disabled agents, and projects without connections. These
tests do not establish Azure deployment, service readiness, or state-backed
upgrade behavior.

## User-assigned identities created in the same deployment

Use readable, stable aliases rather than computed Azure IDs as iteration keys:

```hcl
ai_foundry = {
  user_assigned_identities = {
    application = module.application_identity.resource_id
  }
}
ai_projects = {
  research = {
    name         = "research"
    display_name = "Research"
    description  = "Research project"
    user_assigned_identities = {
      application = module.application_identity.resource_id
    }
  }
}
```

The alias must be known at plan time; its resource ID and principal ID may be
unknown until apply. Reuse the same alias for an identity shared by the account
and a project so dependent-service grants are not duplicated. Give distinct
identities distinct aliases. Do not configure one identity through both the
alias map and `managed_identities.user_assigned_resource_ids`.

The released Foundry identity set remains supported for existing identities whose
IDs are known during planning. Keep existing configurations on that path to
preserve their principal-keyed grant addresses. Switching an existing grant to an
alias changes its Terraform address; it is not an automatic state migration.
Inspect the plan and preserve the existing binding before changing that input.
The new maps do not change Azure assignment naming formulas or existing
system-assigned identity grant keys. The `user-assigned-identities` example
creates an identity and attaches it to the account and two projects in one apply.

## Utility dependency upgrades

The regions utility now uses version `0.13.0`. Its region catalog, filtering and
output definitions are unchanged from `0.12.0`, but it requires a deployment
location and replaces its old telemetry bindings with an empty, subscription-
scoped ARM deployment. With telemetry enabled, the deployment identity needs
permission to manage subscription deployments in the selected location. The
module forwards `enable_telemetry` to this dependency.

Fresh examples use `Azure/avm-utl-naming/azure` `0.2.0` with its default modern
renderer and `names` output. This utility is used only by examples, not by the
reusable Foundry module. Modern names can differ from the previous
`Azure/naming/azurerm` `0.4.3` or `legacy_mode = true` examples. Reusing an existing
example's state can therefore replace resources whose names change; inspect the
complete plan before applying. Existing deployments that need the old naming
contract should retain `legacy_mode = true` and their legacy output references.

## Example Deployments

### Consumer access to Foundry and projects

Use the root `role_assignments` map for access **on the Foundry account** and
`ai_projects[<key>].role_assignments` for access **on that project**. These are
independent of the service-identity grants on dependent storage, Search, and Cosmos DB.
Both maps default to `{}` and create no assignments when omitted. Projects retain
their existing identity and connection defaults.

For example, add these arguments to your Foundry module call:

```hcl
role_assignments = {
  account_reader = {
    role_definition_id_or_name = "Reader"
    principal_id               = var.reader_group_object_id
    principal_type             = "Group"
    description                = "Read access to the Foundry account"
  }
}

ai_projects = {
  research = {
    name         = "research"
    display_name = "Research"
    description  = "Research project"
    role_assignments = {
      developer = {
        role_definition_id_or_name = var.project_role_definition_resource_id
        principal_id               = var.developer_service_principal_object_id
        principal_type             = "ServicePrincipal"
      }
    }
  }
}
```

Use principal **object IDs**, not application/client IDs or managed-identity resource
IDs. Role definitions accept a display name or a fully qualified role definition
resource ID. The AVM interfaces utility resolves names at the exact target scope.
Optional fields are `name` (a lowercase UUID), `description`, `condition`,
`condition_version`, `delegated_managed_identity_resource_id`, and `principal_type`.
Use `condition_version = "2.0"` with a condition. AzAPI makes no Entra principal
lookup, so the standard compatibility field `skip_service_principal_aad_check`
has no effect; supply `principal_type = "ServicePrincipal"` explicitly when required.
The utility generates a persistent random UUID when `name` is omitted. Keep map
keys stable, even when principal IDs are not known until apply. To change a role or
principal after creation, replace the map entry using a new key.

The existing `ai_foundry.role_assignments` interface and its resource addresses
are unchanged. Do not configure the same scope/principal/role combination through
both interfaces: Azure rejects duplicate assignments. No state migration is needed
for this additive capability. Removing a new map entry revokes that assignment on
the next apply; rollback does not alter legacy or dependent-resource grants.

The independently consumable `modules/ai-foundry-project` submodule also accepts
`role_assignments` directly and returns a keyed `role_assignments` summary.

| Example                   | Description                                | Key Features                                      |
| ------------------------- | ------------------------------------------ | ------------------------------------------------- |
| **basic**                 | Minimal AI Foundry deployment              | AI Foundry + Project only, public access          |
| **standard-public**       | Full-featured public deployment            | All services, public endpoints, complete setup    |
| **standard-public-byor**  | Public deployment with existing resources  | Uses existing Storage/KeyVault/Cosmos/Search      |
| **standard-private**      | Enterprise-grade private deployment        | Private endpoints, VNet isolation, Bastion access |
| **standard-private-byor** | Private deployment with existing resources | Private + existing resources combination          |
