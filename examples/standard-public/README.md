# Standard Public Example - Azure AI Foundry Pattern

This example demonstrates the standard deployment of the Azure AI Foundry Pattern with AI agent services but without private endpoints (public configuration).

## Features

- ✅ **Standard Configuration**: Full AI Foundry stack deployment
- ✅ **AI Agent Service**: Container App-based agent service
- ✅ **Multiple OpenAI Models**: GPT-4o, GPT-3.5-turbo, and text-embedding models
- ✅ **Public Endpoints**: All services use public endpoints
- ✅ **Log Analytics Integration**: For monitoring and logging
- ❌ **No Private Endpoints**: All services are publicly accessible

## Resources Created

- Resource Group
- Application Insights (required for AI Foundry)
- Log Analytics Workspace (for Container Apps)
- Storage Account (with system-assigned managed identity)
- Key Vault
- Cosmos DB
- AI Search Service
- Azure OpenAI Service (with multiple model deployments)
- AI Foundry Hub
- AI Foundry Project
- Container App Environment
- Container App (AI Agent Service)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Foundry Standard (Public)             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Azure OpenAI  │  │    AI Search    │  │  Storage     │ │
│  │   Service       │  │                 │  │  Account     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │    Cosmos DB    │  │    Key Vault    │  │  AI Agent    │ │
│  │                 │  │                 │  │  Service     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│                                                             │
│                    All services have public endpoints       │
└─────────────────────────────────────────────────────────────┘
```

## Usage

```bash
# Initialize and deploy
terraform init
terraform plan
terraform apply
```

## AI Agent Service

The AI agent service is deployed as a Container App with:
- **CPU**: 1.0 vCPU
- **Memory**: 2Gi
- **External Ingress**: Enabled (public access)
- **Environment Variables**: Configured for standard public operation

## Outputs

After deployment, you'll receive:
- AI Foundry Hub and Project URLs
- AI Agent Service FQDN and endpoints
- OpenAI endpoint and models
- All service resource IDs and access URLs

## Cost Considerations

This example includes Container Apps and additional services, which may incur higher costs than the basic example.

## Next Steps

- Upgrade to [Standard Private](../standard-private) for private endpoint security
- Customize AI agent container image and configuration
- Add custom environment variables for your specific use case
