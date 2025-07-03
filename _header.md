# Azure AI Foundry Terraform Pattern Module

This Azure Verified Module (AVM) Pattern deploys a complete AI Foundry infrastructure on Azure, providing a production-ready platform for AI applications with supporting services and configurable network isolation.

## Key Features

- **AI Foundry Account & Project**: Core cognitive services with project workspace and OpenAI model deployments
- **Bring Your Own Resources (BYOR)**: Conditional deployment of Storage, Key Vault, Cosmos DB, and AI Search
- **Network Isolation**: Private endpoints and VNet integration support for enterprise security
- **Three Example Configurations**: Basic (minimal), Standard Public (full features), Standard Private (enterprise-grade)

## Architecture

The module uses a conditional deployment pattern where dependent services can be:
- **Created new** (`*_resource_id = null`) - Creates new resources (default behavior)
- **Use existing** (`*_resource_id = "/subscriptions/.../resource-id"`) - Uses provided existing resources

| Feature | Basic | Standard Public | Standard Private |
|---------|-------|-----------------|------------------|
| **AI Foundry** | ✅ Public | ✅ Public | ✅ Private |
| **Storage/Key Vault/Cosmos/Search** | ❌ Not created | ✅ New Public | ✅ New Private |
| **Private Endpoints** | ❌ | ❌ | ✅ All services |
| **VNet & Management** | ❌ | ❌ | ✅ Bastion & VM |
| **Use Case** | Development, PoC | Production | Enterprise, regulated |

## Integration

This module can be used independently or as part of the broader AI/ML platform when combined with the [AI Landing Zone Accelerator](https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone) module.
