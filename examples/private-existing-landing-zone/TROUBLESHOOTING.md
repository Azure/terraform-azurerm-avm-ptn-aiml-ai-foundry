# Troubleshooting & FAQ

Errors are grouped by where they surface. Most of these were hit during a real deployment.

- [Before you start](#before-you-start)
- [Variable and validation errors](#variable-and-validation-errors)
- [Authentication and subscription errors](#authentication-and-subscription-errors)
- [Errors during apply](#errors-during-apply)
- [Networking and DNS](#networking-and-dns)
- [Azure AI Video Indexer](#azure-ai-video-indexer)
- [Destroy and redeploy](#destroy-and-redeploy)
- [FAQ](#faq)

---

## Before you start

### How long should this take?

| Phase | Expected |
| --- | --- |
| `terraform init` | 1-2 min |
| `terraform plan` | 30 s - 2 min |
| `terraform apply` | **30-60 min** |

Within the apply, the slow parts are AI Search (10-15 min), Cosmos DB (5-10 min), each private
endpoint (1-3 min), and a hard-coded **5 minute wait** after the Foundry account is created.

### How do I know if it is stuck or just slow?

`Still creating... [Nm elapsed]` ticking every 10 seconds means Terraform is actively polling
Azure. That is healthy, however long it has been going.

Treat it as a real problem when:

- the elapsed counter **stops advancing**, or
- a single resource passes **~30 minutes**.

If nothing is printing at all, check whether the process is even alive:

```powershell
Get-Process terraform -ErrorAction SilentlyContinue
```

**Never Ctrl+C a running apply.** Terraform will not roll back, and killing it mid-create can
leave resources in Azure that are not in state - which is harder to clean up than any failure.

---

## Variable and validation errors

These all fail at **plan** time, within seconds, and cost nothing.

### `location must be a region where the Foundry Agent Service supports private VNet injection`

Your region does not support agent VNet injection. `westus2` is the most common surprise - it is
not supported despite supporting almost everything else in Azure.

Pick a region from the list in `variables.tf`, and remember that the **VNet holding the agent
subnet must be in the same region as the Foundry account**. Changing `location` on an existing
deployment therefore means new networking too - see
[Can I change the region after deploying?](#can-i-change-the-region-after-deploying)

### `base_name must be ...`

`base_name` must match `^[a-z0-9][a-z0-9-]{1,11}$` - lowercase only, 2-12 characters. Storage
accounts and Cosmos DB have strict global naming rules, so uppercase and underscores are rejected
up front rather than failing midway through an apply.

### `private_endpoint_subnet_resource_id must be a fully qualified subnet resource ID`

The value must end in `/virtualNetworks/<vnet>/subnets/<subnet>`. A common mistake is pasting the
ID of a *private endpoint* resource (`.../privateEndpoints/<name>`) instead of a subnet. Get the
right one with:

```powershell
az network vnet subnet show -g <rg> --vnet-name <vnet> -n <subnet> --query id -o tsv
```

### `Provide agent_subnet.resource_id for an existing subnet, or set create = true together with ...`

Pick exactly one of the two shapes:

```hcl
# Option A - the platform team already created it
agent_subnet = {
  resource_id = "/subscriptions/.../subnets/snet-ai-agents"
}

# Option B - create it here
agent_subnet = {
  create                              = true
  name                                = "snet-ai-agents"
  address_prefixes                    = ["10.100.250.0/24"]
  virtual_network_name                = "vnet-spoke-ai"
  virtual_network_resource_group_name = "rg-network"
}
```

Option B requires all four of `address_prefixes`, `virtual_network_name`,
`virtual_network_resource_group_name` and `create = true`.

### I commented out a variable and the behaviour did not change

Several variables have **non-empty defaults**. Commenting out a block falls back to the default
rather than disabling the feature. The one that bites people is `ai_model_deployments`, which
defaults to deploying `gpt-4.1`. To deploy no models you must set it **explicitly**:

```hcl
ai_model_deployments = {}
```

---

## Authentication and subscription errors

### `the provided subscription ID ... is not known by Azure CLI`

The subscription in `terraform.tfvars` is not one your CLI session can see. Either you are not
logged in, or you are logged into the wrong tenant.

```powershell
az login
az account set --subscription "<your-subscription-id>"
az account show --query "{sub:name, id:id, tenant:tenantId}" -o table
```

### `Resource group '<name>' could not be found` - but it definitely exists

Almost always the **wrong subscription is selected**, not a missing resource group.

```powershell
az account set --subscription "<your-subscription-id>"
az group show -n <rg> --query name -o tsv
```

This happens most often in **Cloud Shell**, which defaults to your first or last-used subscription
and has a completely separate auth context from your local terminal. Terraform uses the local one,
pinned via `subscription_id` in tfvars, so the two can disagree silently.

### `AuthorizationFailed` on a role assignment

You need `Owner`, or `Contributor` **plus** `User Access Administrator`. Plain `Contributor` cannot
create role assignments, and this configuration creates several on the Foundry account, Storage,
Cosmos DB and AI Search.

### `PrincipalNotFound` on a role assignment

The `principal_id` in `ai_foundry.role_assignments` does not exist in the tenant, or was created
seconds ago and has not replicated. Verify it:

```powershell
az ad group show --group "<object-id>" --query id -o tsv
```

If the principal is genuinely new, wait a minute and re-apply.

---

## Errors during apply

### `Private VNet setup for Microsoft Foundry Agent Service is not supported in this region`

The region does not support agent VNet injection. Newer versions of this configuration catch this
at plan time via the `location` validation; if you see it during an apply, your `variables.tf`
predates that guard.

This is **not** recoverable in place - the region has to change, which means new networking. See
[Can I change the region after deploying?](#can-i-change-the-region-after-deploying)

### `ServiceUnavailable ... high demand in <region> ... for the zonal redundant (Availability Zones) accounts`

Azure is out of **zone-redundant** Cosmos DB capacity in that region. Deploy a single-zone account
instead:

```hcl
cosmosdb = {
  zone_redundant = false
}
```

Then delete the half-created account (see the next entry) and re-apply.

The trade-off is real: a single-zone account loses availability if its zone fails. For production,
request zonal capacity at <https://aka.ms/cosmosdbquota> or choose another region rather than
leaving this off permanently.

### `a resource with the ID ... already exists - to be managed via Terraform this resource needs to be imported into the State`

A previous apply created the resource in Azure but failed before recording it in state. The
resource is real, but Terraform does not know about it.

For a resource that failed to provision correctly, **delete it** rather than importing - importing
a broken or wrongly-configured resource just means Terraform plans to destroy and recreate it
anyway:

```powershell
az cosmosdb delete -n <name> -g <rg> --yes          # Cosmos DB
az resource delete --ids "<resource-id>"            # anything else
```

Confirm it is gone before re-running:

```powershell
az cosmosdb show -n <name> -g <rg>    # want: ResourceNotFound
```

Import is the right call only when the resource is genuinely correct and you want to adopt it:

```powershell
terraform import 'module.cosmosdb.azurerm_cosmosdb_account.this' "<resource-id>"
```

### `InsufficientResourcesAvailable - The region '<region>' is currently out of the resources required to provision new services`

Seen on **Azure AI Search**. This is region-wide capacity exhaustion, not a quota you can raise -
the region has no spare Search infrastructure. It is unrelated to your subscription limits, and
waiting may or may not help.

In rough order of cost to try:

1. **Reduce the capacity ask.** The default is `standard` with 2 replicas, which is 2 search units.
   One replica halves it:

   ```hcl
   ai_search = { replica_count = 1 }
   ```

   Note that a single replica carries no read SLA.

2. **Try the `basic` SKU**, which draws from a different capacity pool:

   ```hcl
   ai_search = { sku = "basic" }
   ```

3. **Deploy AI Search in another region.** AI Foundry supports its dependent data services outside
   the Foundry region:

   ```hcl
   ai_search = { location = "westus3" }
   ```

   The private endpoint still lives in the workload VNet and the DNS zone is unchanged, so
   resolution works exactly as before. The trade-offs are cross-region latency on vector queries
   and egress charges. Unlike a Foundry region change, **this does not require new networking** -
   only the agent subnet VNet is pinned to the Foundry region.

### `InsufficientQuota` / `exceeded call rate limit` on a model deployment

You do not have quota for that model, version, or SKU in this region. Check what exists:

```powershell
az cognitiveservices usage list -l <region> -o table
```

**The numeric column is current usage, not the limit.** A row showing `0.0` means zero consumed,
not zero available - this is very easy to misread. Look at the limit column.

If the models you want are absent entirely, there is no quota to consume. Deploy with
`ai_model_deployments = {}`, then request quota and add them later. Quota is **per region**, so
re-check after any region change.

Once the Foundry account exists, the authoritative list of what you can deploy is:

```powershell
az cognitiveservices account list-models -n <foundry-account> -g <rg> `
  --query "[].{name:name, format:format, version:version}" -o table
```

### `Capability host creation failed ... is not registered with the required resource providers ... Microsoft.App and Microsoft.ContainerService`

The Foundry **account** was created successfully, but the **capability host** - the managed runtime
that actually executes agents - failed. That runtime is built on Azure Container Apps and AKS, so
the subscription must have both resource providers registered. Many enterprise subscriptions have
RP registration locked down or simply never needed these.

Register them, then wait until both report `Registered`:

```powershell
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.ContainerService

az provider show -n Microsoft.App --query registrationState -o tsv
az provider show -n Microsoft.ContainerService --query registrationState -o tsv
```

Registration usually takes 2-5 minutes. **Do not re-apply while either still says `Registering`** -
you will hit the same error.

Then check whether the failed account shell is still present, because the account name is taken
until it is purged:

```powershell
az cognitiveservices account show -n <foundry-account> -g <rg> `
  --query "properties.provisioningState" -o tsv
```

- **Not found** - re-apply.
- **`Succeeded`** - re-apply; Terraform retries the capability host against the existing account.
- **`Failed`** - delete *and purge* it first, otherwise the next apply fails with
  `already exists`:

  ```powershell
  az cognitiveservices account delete -n <foundry-account> -g <rg>
  az cognitiveservices account purge -n <foundry-account> -g <rg> -l <region>
  ```

  The purge is required - Cognitive Services accounts soft-delete, and a soft-deleted name blocks
  reuse. See also
  [`already exists`](#a-resource-with-the-id--already-exists---to-be-managed-via-terraform-this-resource-needs-to-be-imported-into-the-state).

If you cannot register resource providers yourself, this needs a subscription Owner or your
platform team. Registration is subscription-wide and only has to be done once.

### `RequestDisallowedByPolicy`

An Azure Policy in your management group blocked a resource. The error names the policy
assignment. Common culprits: required tags, allowed-region lists, mandatory customer-managed keys,
or deny rules on public network access toggles.

Either get an exemption for the workload resource group, or adjust `tags` / `resource_names` to
comply. Note that CMK is **not** enabled by this configuration - if your landing zone mandates it,
you will need to extend the `ai_foundry` variable.

### The apply failed partway through. Do I need to start over?

**No, and do not run `terraform destroy`.** Everything created so far is recorded in state.
Fix the cause and re-run:

```powershell
terraform plan -out tfplan
terraform apply tfplan
```

Terraform creates only what is missing. The plan will show far fewer resources than the first run.

### The apply failed with something transient. Will re-running fix it?

Often, yes. RBAC propagation delays are the usual cause - a role assignment is created, then used
before Entra ID has replicated it. A straight re-apply normally clears those. If the *same* error
recurs twice, it is not transient.

---

## Networking and DNS

### Names resolve to public IPs instead of private ones

The VNet is not linked to the private DNS zones, or the A record was never registered.

If this configuration owns the zones (`create_private_dns_zones = true`), make sure every VNet
that needs to resolve is listed:

```hcl
private_dns_zone_virtual_network_resource_ids = {
  spoke   = "/subscriptions/.../virtualNetworks/vnet-spoke-ai"
  jumpbox = "/subscriptions/.../virtualNetworks/vnet-management"
}
```

If the platform owns DNS via policy, confirm the DINE assignment actually ran - policy remediation
is not instant, and private endpoints created before the assignment existed are not retroactively
fixed without a remediation task.

Check what Terraform attached:

```powershell
terraform output private_dns_zone_ids_in_use
```

Empty values mean DNS is deliberately left to policy.

### I cannot reach the Foundry portal or any of the data services

Expected. Everything is deployed with public network access disabled. You need network line of
sight into the VNet: a jump box, Azure Bastion, VPN, or ExpressRoute through the hub.

A VNet with no peering resolves and routes correctly **only from inside that VNet**.

### Agents cannot reach Storage, Cosmos DB or AI Search

The agent subnet and the private endpoint subnet must be in the **same VNet**, or in peered VNets.
If they are in separate unpeered VNets, DNS resolves to a private IP but packets have no route -
which looks like a hang or a timeout rather than a clean error.

### `PrivateEndpointNetworkPoliciesEnabled` or private endpoint creation fails

```powershell
az network vnet subnet update --ids "<subnet-id>" --private-endpoint-network-policies Disabled
```

---

## Azure AI Video Indexer

Only relevant when `deploy_video_indexer = true`.

### The Video Indexer web app will not load, or the Insights/Editor widgets are blank

This is expected with the default settings, not a bug.

With `video_indexer.public_network_access_enabled = false` the account is reachable only over its
private endpoint, and **the Video Indexer web app and the Insights and Editor widgets do not
support private endpoints**. The account is usable through the REST API only.

If your users need the portal, set:

```hcl
video_indexer = {
  public_network_access_enabled = true
}
```

and accept a publicly reachable control plane. The Player embeddable widget is the exception - it
works with private endpoints when the embed URL includes the `accountName` query parameter and the
iframe carries `allow="local-network-access"`.

### `deploy_video_indexer = true` needs a private DNS zone for privatelink.api.videoindexer.ai

Enabling Video Indexer adds an eighth private DNS zone to the set. The configuration fails fast
rather than deploying an endpoint that resolves publicly. Pick one:

```hcl
# consume a specific platform zone
private_dns_zone_resource_ids = {
  video_indexer = "/subscriptions/<sub>/resourceGroups/<dns-rg>/providers/Microsoft.Network/privateDnsZones/privatelink.api.videoindexer.ai"
}

# or derive it from the platform DNS resource group
private_dns_zone_resource_group_id = "/subscriptions/<sub>/resourceGroups/<dns-rg>"

# or, sandbox only, create it here
create_private_dns_zones = true
```

If the zone does not exist in your hub yet, the platform team has to create it - it is not one of
the zones a landing zone typically deploys by default.

### The region does not offer Video Indexer

Video Indexer is available in fewer regions than AI Foundry, and there is **no requirement for the
two to match**. Point it somewhere else:

```hcl
video_indexer = {
  location = "eastus2"
}
```

The dedicated storage account follows this region, because Video Indexer requires its storage
account to be co-located. The private endpoint still lives in the workload VNet, so resolution is
unchanged.

### Storage access errors from the Video Indexer account

The account reaches its storage account as a trusted Azure service, using managed identity, with
public network access disabled. If you see access failures that look like authentication rather
than networking, the fastest test is to re-enable shared keys:

```hcl
video_indexer = {
  storage_account_shared_key_enabled = true
}
```

If that resolves it, the cause is an identity or role propagation issue rather than the firewall.
Note this is a **diagnostic step, not a destination** - shared keys are disabled by default
deliberately. Check that both role assignments exist on the storage account:

```powershell
az role assignment list --scope <video-indexer-storage-account-id> `
  --query "[].{principal:principalId, role:roleDefinitionName}" -o table
```

You should see `Storage Blob Data Contributor` twice: once for the user-assigned identity and once
for the account's system-assigned identity.

### Summarization fails after setting `connect_to_ai_foundry = true`

That setting wires Video Indexer to the Foundry account, but it does not deploy a model. With
`ai_model_deployments = {}` there is nothing to call, so summarization fails at runtime while the
deployment itself succeeds. Deploy a chat model first - see
[Can I add models later](#can-i-add-models-later-without-recreating-anything).

### Removing Video Indexer

Set `deploy_video_indexer = false` and re-apply. The account, its dedicated storage account, the
identity, the role assignments and the private endpoint are all destroyed; nothing in the Foundry
stack is touched. **The dedicated storage account is deleted with it**, so export anything you
need first.

---

## Destroy and redeploy

### `terraform destroy` hangs or fails on the agent subnet

Deleting an agent-injected Foundry account leaves a **service association link** on the delegated
subnet until the soft-deleted account is purged. The subnet cannot be deleted while that link
exists.

Options:

- set `purge_soft_deleted_foundry_on_destroy = true` before destroying - this adds a destroy-time
  purge plus a 20 minute cooldown, or
- purge manually, then re-run the destroy:

```powershell
az resource delete --ids "/subscriptions/<sub>/providers/Microsoft.CognitiveServices/locations/<region>/resourceGroups/<rg>/deletedAccounts/<account-name>"
```

A destroy may legitimately need two passes.

### Can I change the region after deploying?

Not in place. Azure resources cannot move regions, and because the Foundry account must sit in the
same region as its VNet, the networking has to move too.

1. `terraform destroy`
2. Create a new VNet and private endpoint subnet in the target region, with a non-overlapping
   address space so it can be peered later
3. Update `location`, `private_endpoint_subnet_resource_id`, `agent_subnet` and
   `private_dns_zone_virtual_network_resource_ids` in tfvars
4. `terraform plan -out tfplan` and apply

Re-check model quota afterwards - it is per region.

### Resource names changed after a redeploy

Names include a random suffix from `random_string.token`, which is regenerated when state is
destroyed. Set `resource_names` explicitly if you need stable names across rebuilds.

---

## FAQ

### Can I run this without model deployments?

Yes, and it is the right move when you have no quota:

```hcl
ai_model_deployments = {}
```

The full platform deploys. Add models later by editing tfvars and re-applying - no teardown.

### Can I add models later without recreating anything?

Yes. Model deployments are child resources of the Foundry account. Adding entries to
`ai_model_deployments` and re-applying only creates the new deployments.

### Do I need a Key Vault?

No. Set `deploy_key_vault = false`. It is created by default because many agent scenarios expect
somewhere to store connection secrets.

### Why are the data services created separately instead of by the pattern module?

This is the module's documented production path (`create_byor = false`). The data services keep
their own lifecycle, naming and policy posture, they survive a `terraform destroy` of the Foundry
stack, and they can be shared across projects.

### Can I use an existing resource group?

Yes:

```hcl
resource_group = {
  create = false
  name   = "rg-my-existing-group"
}
```

The group is looked up with a data source instead of created. It must already exist, otherwise the
plan fails.

### What are the `local_authentication_disabled` deprecation warnings?

They come from the upstream AVM Cosmos DB module, not this configuration. Harmless, and they will
disappear when that module updates for AzureRM v5.

### Is this safe to run in a real landing zone?

Yes, with one exception: **never set `create_private_dns_zones = true` outside a sandbox.** Private
DNS is a platform responsibility, and a second copy of the `privatelink.*` zones in a spoke causes
split-brain resolution that is painful to unpick. Those zones are also destroyed with the workload.

In a real landing zone use either `private_dns_zone_resource_group_id` (platform-owned zones) or
`manage_private_dns_zone_groups = false` (policy-driven DNS).
