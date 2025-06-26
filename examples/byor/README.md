# Bring Your Own Resources (BYOR) Example

This example demonstrates how to use the AI Foundry pattern with existing (bring your own) resources. It creates prerequisite resources first and then references them as existing resources in the AI Foundry module.

## Features

This example includes:

- **Existing Storage Account**: Creates a storage account and uses it as an existing resource
- **Existing Key Vault**: Creates a Key Vault and uses it as an existing resource
- **Existing Cosmos DB**: Creates a Cosmos DB account and uses it as an existing resource
- **Existing AI Search**: Creates an AI Search service and uses it as an existing resource
- **AI Services**: Creates new AI Services with model deployments
- **AI Foundry Project**: Creates the AI Foundry project referencing the existing resources
- **Public Access**: All resources use public endpoints (no private endpoints)

## Architecture

```
┌─────────────────────────────────────────┐
│           Resource Group                │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────┐  ┌───────────────┐ │
│  │  Storage Acct   │  │   Key Vault   │ │
│  │   (existing)    │  │  (existing)   │ │
│  └─────────────────┘  └───────────────┘ │
│                                         │
│  ┌─────────────────┐  ┌───────────────┐ │
│  │   Cosmos DB     │  │  AI Search    │ │
│  │   (existing)    │  │  (existing)   │ │
│  └─────────────────┘  └───────────────┘ │
│                                         │
│  ┌─────────────────┐  ┌───────────────┐ │
│  │  AI Services    │  │ AI Foundry    │ │
│  │    (new)        │  │ Project (new) │ │
│  └─────────────────┘  └───────────────┘ │
│                                         │
│  ┌─────────────────┐                    │
│  │ Log Analytics   │                    │
│  │   Workspace     │                    │
│  └─────────────────┘                    │
└─────────────────────────────────────────┘
```

## Usage

1. **Set up your environment**: Ensure you have the Azure CLI installed and are logged in to your Azure subscription.

2. **Create a resource group**: This example requires an existing resource group.
   ```bash
   az group create --name "rg-ai-foundry-byor" --location "East US 2"
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan -var="resource_group_name=rg-ai-foundry-byor" -var="location=East US 2"
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply -var="resource_group_name=rg-ai-foundry-byor" -var="location=East US 2"
   ```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_group_name` | The name of an existing resource group to deploy resources into | `string` | n/a | yes |
| `location` | The Azure region where the resources will be deployed | `string` | n/a | yes |
| `enable_telemetry` | Controls whether telemetry is enabled for the module | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `ai_foundry_project_id` | The resource ID of the AI Foundry project |
| `ai_foundry_project_name` | The name of the AI Foundry project |
| `ai_services_id` | The resource ID of the AI Services account |
| `ai_services_endpoint` | The endpoint URL of the AI Services account |
| `storage_account_id` | The resource ID of the storage account (BYO resource) |
| `key_vault_id` | The resource ID of the Key Vault (BYO resource) |
| `cosmos_db_id` | The resource ID of the Cosmos DB account (BYO resource) |
| `ai_search_id` | The resource ID of the AI Search service (BYO resource) |
| `log_analytics_workspace_id` | The resource ID of the Log Analytics Workspace |

## Resources Created

### Prerequisite Resources (used as BYO)
- **Storage Account**: Standard LRS storage with blob versioning and change feed enabled
- **Key Vault**: Standard SKU with soft delete (7 days retention)
- **Cosmos DB**: GlobalDocumentDB with BoundedStaleness consistency
- **AI Search**: Standard SKU search service with default configuration

### AI Foundry Resources
- **AI Services**: Cognitive Services account with OpenAI model deployments
- **AI Foundry Project**: ML workspace configured with existing resources
- **Log Analytics Workspace**: For monitoring and diagnostics

## Key Features Demonstrated

1. **Resource Reuse**: Shows how to reference existing Azure resources in the AI Foundry pattern
2. **Resource ID Passing**: Demonstrates proper way to pass existing resource IDs to the module
3. **Mixed Resource Creation**: Creates some resources as prerequisites and others through the module
4. **Public Endpoints**: All resources use public access (no private networking)
5. **Model Deployments**: Includes GPT-4o model deployment for AI services

## Notes

- This example creates the "existing" resources in the same Terraform configuration for demonstration purposes
- In a real-world scenario, these existing resources would typically be created separately and their IDs passed as variables
- All resources use public endpoints for simplicity
- The example includes proper telemetry and logging configuration

## Clean Up

To clean up the resources created by this example:

```bash
terraform destroy -var="resource_group_name=rg-ai-foundry-byor" -var="location=East US 2"
```
