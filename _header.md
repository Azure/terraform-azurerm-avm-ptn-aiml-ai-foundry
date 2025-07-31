# Azure AI Foundry Terraform Pattern Module

This Azure Verified Module (AVM) Pattern deploys a complete AI Foundry infrastructure on Azure, providing a production-ready platform for AI applications with supporting services and configurable network isolation.

## Key Features

- **AI Foundry Account & Project**: Core cognitive services with project workspace and OpenAI model deployments
- **Bring Your Own Resources (BYOR)**: Conditional deployment of Storage, Key Vault, Cosmos DB, and AI Search
- **Network Isolation**: Private endpoints and VNet integration support for enterprise security
- **Three Example Configurations**: Basic (minimal), Standard Public (full features), Standard Private (enterprise-grade)

## Resource Types

This module deploys resources in three categories:

| Type      | Resource                        | Code Location                | Code / Deployment Notes                |
| --------- | ------------------------------- | ---------------------------- | -------------------------------------- |
| Required  | AI Foundry                      | Root module                  | Always deploy                          |
| Required  | AI Foundry Connections          | Root module                  | Always deploy (BYOR dependency)       |
| Required  | AI Foundry Project              | Root module                  | Always deploy                          |
| Required  | AI Foundry Project Connections  | Root module                  | Always deploy (BYOR dependency)       |
| Required  | AI Foundry Agent Service        | Root module                  | Private deployment only                |
| Required  | RBACs                           | Root module                  | Always deploy                          |
| Required  | Resource Lock                   | Root module                  | Always deploy                          |
| Dependent | Virtual Network                 | Example main.tf              | Use resource block, not AVM res module |
| Dependent | Subnets                         | Example main.tf              | Use resource block, not AVM res module |
| Dependent | Private DNS Zones               | Example main.tf              | Use resource block, not AVM res module |
| Dependent | Private DNS Zone vNet Links     | Example main.tf              | Use resource block, not AVM res module |
| Dependent | Bastion                         | Example main.tf              | Use AVM Resource Module                |
| Dependent | Virtual Machine                 | Example main.tf              | Use AVM Resource Module                |
| Dependent | Log Analytics Workspace         | Example main.tf              | Use resource block, not AVM res module |
| BYOR      | Key Vault                       | main.byor.tf                 | Use AVM Resource Module                |
| BYOR      | Search Service                  | main.ai_search.tf            | Use azapi_resource                     |
| BYOR      | Storage Account                 | main.byor.tf                 | Use AVM Resource Module                |
| BYOR      | CosmosDB                        | main.byor.tf                 | Use AVM Resource Module                |

- **Required**: Resources needed to deploy the basic example
- **Dependent**: Resources needed to deploy examples beyond basic
- **BYOR**: Resources identified as "Bring Your Own Resources" with conditional deployment

## Example Deployments

| Example | Description | Use Case | Key Features |
|---------|-------------|----------|--------------|
| **basic** | Minimal AI Foundry deployment | Development, PoC, Testing | AI Foundry + Project only, public access |
| **standard-public** | Full-featured public deployment | Production workloads | All services, public endpoints, complete setup |
| **standard-public-byor** | Public deployment with existing resources | Hybrid scenarios | Uses existing Storage/KeyVault/Cosmos/Search |
| **standard-private** | Enterprise-grade private deployment | Regulated industries | Private endpoints, VNet isolation, Bastion access |
| **standard-private-byor** | Private deployment with existing resources | Enterprise hybrid | Private + existing resources combination |

## Integration

This module can be used independently or as part of the broader AI/ML platform when combined with the [AI Landing Zone Accelerator](https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone) module.
