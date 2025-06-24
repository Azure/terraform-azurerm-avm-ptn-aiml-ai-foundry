# Basic Example - Azure AI Foundry Pattern

This example demonstrates the basic deployment of the Azure AI Foundry Pattern with minimal configuration and no private endpoints.

## Features

- ✅ **Minimal Configuration**: Uses only required parameters
- ✅ **Public Endpoints**: All services use public endpoints for simplicity
- ✅ **Basic OpenAI Model**: Deploys GPT-4o model
- ✅ **AI Foundry Project**: Creates an AI Foundry project workspace
- ❌ **No Agent Service**: AI agent service is disabled for basic setup
- ❌ **No Private Endpoints**: All services are publicly accessible

## Resources Created

- Resource Group
- Application Insights (required for AI Foundry)
- Storage Account (with system-assigned managed identity)
- Key Vault
- Cosmos DB
- AI Search Service
- Azure OpenAI Service (with GPT-4o deployment)
- AI Foundry Hub
- AI Foundry Project

## Usage

```bash
# Initialize and deploy
terraform init
terraform plan
terraform apply
```

## Outputs

After deployment, you'll receive:
- AI Foundry Hub and Project URLs
- OpenAI endpoint
- Storage Account details
- Key Vault URI
- All service resource IDs

## Cost Considerations

This example uses standard SKUs and may incur costs. Consider using development/testing SKUs for evaluation purposes.

## Next Steps

- Upgrade to [Standard Public](../standard-public) for AI agent services
- Upgrade to [Standard Private](../standard-private) for private endpoint security
