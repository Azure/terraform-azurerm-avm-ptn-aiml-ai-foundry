# Private example

This example deploys a simple version of the module with private endpoints enabled.

## Architecture

This example deploys AI Foundry with private networking and supporting services:

```mermaid
graph TB
    subgraph "Azure Resource Group"
        subgraph "Virtual Network"
            subgraph "Subnets"
                PESNET[Private Endpoint<br/>Subnet]
                BASSNET[Bastion Subnet]
                VMSNET[VM Subnet]
            end
        end
        
        subgraph "Core Services"
            AF[AI Foundry<br/>Account]
            AFP[AI Foundry<br/>Project]
            AFS[AI Agent<br/>Service]
        end
        
        subgraph "BYOR Services"
            KV[Key Vault]
            SA[Storage Account]
            CDB[Cosmos DB]
            AIS[AI Search]
        end
        
        subgraph "Management"
            BAS[Bastion Host]
            VM[Virtual Machine]
            DNS[Private DNS<br/>Zones]
            PE[Private<br/>Endpoints]
        end
    end
    
    %% Core relationships
    AF --> AFP
    AFP --> AFS
    AF -.-> KV
    AF -.-> SA
    AF -.-> CDB
    AF -.-> AIS
    
    %% Private connectivity
    PE -.-> AF
    PE -.-> KV
    PE -.-> SA
    PE -.-> CDB
    PE -.-> AIS
    PESNET --> PE
    DNS --> PE
    
    %% Management access
    BAS --> VM
    BASSNET --> BAS
    VMSNET --> VM
    
    classDef required fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef byor fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef network fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    
    class AF,AFP,AFS required
    class KV,SA,CDB,AIS byor
    class PESNET,BASSNET,VMSNET,BAS,VM,DNS,PE network
```

**Components:**
- 🔷 **Core AI Foundry** with private access
- 🔶 **Supporting services** (Key Vault, Storage, Cosmos DB, AI Search)  
- 🔷 **Private networking** with VNet isolation and Bastion access
- All services connected via private endpoints for secure communication
