# Private example

This example deploys a simple version of the module with private endpoints enabled.

## Architecture

This example uses externally created BYOR services with AI Foundry using private networking:

```mermaid
graph TB
    subgraph "Azure Resource Group"
        subgraph "Virtual Network"
            subgraph "Subnets"
                PESNET[Private Endpoint<br/>Subnet]
                AGENTSNET[Agent Services<br/>Subnet]
                BASSNET[Bastion Subnet]
                VMSNET[VM Subnet]
            end
        end
        
        subgraph "Core Services"
            AF[AI Foundry<br/>Account]
            AFP[AI Foundry<br/>Project]
            AFS[AI Agent<br/>Service]
            AMD[AI Model<br/>Deployment]
        end
        
        subgraph "External BYOR Services"
            KV[Key Vault]
            SA[Storage Account]
            CDB[Cosmos DB]
            AIS[AI Search]
        end
        
        subgraph "Private Networking"
            DNS[Private DNS<br/>Zones]
            PE[Private<br/>Endpoints]
        end
        
        subgraph "Management Access"
            BAS[Bastion Host]
            VM[Virtual Machine]
        end
        
        subgraph "Supporting Services"
            LAW[Log Analytics<br/>Workspace]
        end
    end
    
    %% Core relationships
    AF --> AFP
    AF --> AMD
    AFP --> AFS
    AFP -.-> KV
    AFP -.-> SA
    AFP -.-> CDB
    AFP -.-> AIS
    
    %% Private connectivity
    PE -.-> AF
    PE -.-> KV
    PE -.-> SA
    PE -.-> CDB
    PE -.-> AIS
    PESNET --> PE
    AGENTSNET --> AFS
    DNS --> PE
    
    %% Management access
    BAS --> VM
    BASSNET --> BAS
    VMSNET --> VM
    
    %% Supporting relationships
    LAW -.-> AF
    
    classDef required fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef byor fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,stroke-dasharray: 5 5
    classDef network fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef support fill:#fff3e0,stroke:#e65100,stroke-width:2px
    
    class AF,AFP,AFS,AMD required
    class KV,SA,CDB,AIS byor
    class PESNET,AGENTSNET,BASSNET,VMSNET,DNS,PE,BAS,VM network
    class LAW support
```

**Components:**
- 🔷 **Core AI Foundry** with private access and Agent Services
- 🔶 **External BYOR Services** (Key Vault, Storage, Cosmos DB, AI Search) - dashed borders indicate external resources
- 🔷 **Private Networking** with VNet isolation, dedicated subnets, and private endpoints
- 🔷 **Management Access** via Bastion Host and VM for secure administration
- 🔸 **Supporting Services** (Log Analytics Workspace)

This configuration demonstrates the most comprehensive deployment pattern using external BYOR services with full private networking and secure management access.
