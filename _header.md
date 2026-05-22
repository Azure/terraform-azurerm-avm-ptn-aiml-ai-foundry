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

## Example Deployments

| Example                   | Description                                | Key Features                                      |
| ------------------------- | ------------------------------------------ | ------------------------------------------------- |
| **basic**                 | Minimal AI Foundry deployment              | AI Foundry + Project only, public access          |
| **standard-public**       | Full-featured public deployment            | All services, public endpoints, complete setup    |
| **standard-public-byor**  | Public deployment with existing resources  | Uses existing Storage/KeyVault/Cosmos/Search      |
| **standard-private**      | Enterprise-grade private deployment        | Private endpoints, VNet isolation, Bastion access |
| **standard-private-byor** | Private deployment with existing resources | Private + existing resources combination          |
