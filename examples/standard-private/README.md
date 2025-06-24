# Standard Private Example - Azure AI Foundry Pattern

This example demonstrates the full enterprise deployment of the Azure AI Foundry Pattern with private endpoints, VNet integration, and AI agent services.

## Features

- ✅ **Enterprise Security**: Full private endpoint configuration
- ✅ **VNet Integration**: Custom VNet with dedicated subnets
- ✅ **Private DNS Zones**: Automated DNS zone creation and VNet linking
- ✅ **AI Agent Service**: Container App with dedicated subnet
- ✅ **Multiple OpenAI Models**: GPT-4o, GPT-3.5-turbo, and text-embedding models
- ✅ **Private Ingress**: AI agent service uses internal load balancer
- ✅ **Complete Isolation**: All services communicate privately

## Resources Created

### Core AI Services
- Resource Group
- Application Insights (required for AI Foundry)
- Log Analytics Workspace (for Container Apps)
- Storage Account (with private endpoint)
- Key Vault (with private endpoint)
- Cosmos DB (with private endpoint)
- AI Search Service (with private endpoint)
- Azure OpenAI Service (with private endpoint)
- AI Foundry Hub (with private endpoint)
- AI Foundry Project (with private endpoint)

### Networking Infrastructure
- Virtual Network (10.0.0.0/16)
- Private Endpoint Subnet (10.0.1.0/24)
- Agent Services Subnet (10.0.2.0/23)
- Private DNS Zones for all services:
  - `privatelink.blob.core.windows.net`
  - `privatelink.vaultcore.azure.net`
  - `privatelink.documents.azure.com`
  - `privatelink.search.windows.net`
  - `privatelink.openai.azure.com`
  - `privatelink.api.azureml.ms`
- VNet Links for all private DNS zones

### AI Agent Service
- Container App Environment (with subnet delegation)
- Container App (AI Agent Service with private ingress)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                VNet (10.0.0.0/16)                               │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │           Private Endpoint Subnet (10.0.1.0/24)            │ │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌──────┐  │ │
│  │  │   PE    │ │   PE    │ │   PE    │ │   PE    │ │  PE  │  │ │
│  │  │Storage  │ │KeyVault │ │CosmosDB │ │AI Search│ │OpenAI│  │ │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └──────┘  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │          Agent Services Subnet (10.0.2.0/23)               │ │
│  │                ┌─────────────────────┐                      │ │
│  │                │  Container App Env  │                      │ │
│  │                │  ┌───────────────┐  │                      │ │
│  │                │  │  AI Agent     │  │                      │ │
│  │                │  │  Service      │  │                      │ │
│  │                │  └───────────────┘  │                      │ │
│  │                └─────────────────────┘                      │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│           Private DNS Zones + VNet Links                        │
└─────────────────────────────────────────────────────────────────┘
```

## Network Configuration

### Subnet Allocation
- **Private Endpoints**: 10.0.1.0/24 (254 addresses)
- **Agent Services**: 10.0.2.0/23 (510 addresses)

### Private DNS Integration
All services are configured with private DNS zones and VNet links for seamless private resolution.

## Usage

```bash
# Initialize and deploy
terraform init
terraform plan
terraform apply
```

## AI Agent Service Configuration

The AI agent service is deployed with:
- **CPU**: 1.0 vCPU
- **Memory**: 2Gi
- **Ingress**: Internal only (private)
- **Subnet**: Dedicated Container App subnet with delegation
- **Environment**: Configured for private operations

## Security Features

1. **Network Isolation**: All services communicate through private endpoints
2. **DNS Resolution**: Private DNS zones ensure proper name resolution
3. **Subnet Segmentation**: Separate subnets for different workload types
4. **Internal Load Balancer**: Agent service uses internal load balancing

## Outputs

After deployment, you'll receive:
- AI Foundry Hub and Project URLs (accessible via private network)
- VNet and subnet information
- Private endpoint details and IP addresses
- AI Agent Service internal FQDN

## Cost Considerations

This example includes VNet, private endpoints, Container Apps, and premium SKUs, resulting in higher costs than public configurations.

## Prerequisites

- Ensure you have appropriate permissions to create VNets and private endpoints
- Consider network connectivity requirements for accessing private resources

## Next Steps

- Configure VPN or ExpressRoute for secure access to private resources
- Customize network security groups for additional security
- Implement Azure Bastion for secure VM access if needed
