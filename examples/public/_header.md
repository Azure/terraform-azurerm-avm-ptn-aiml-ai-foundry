# Public example

This deploys a simple version of the module without private endpoints.

## Architecture

This example deploys AI Foundry with all BYOR services using public access:

```mermaid
graph TB
    subgraph "Azure Resource Group"
        subgraph "Core AI Foundry"
            AF[AI Foundry<br/>Account]
            AFP[AI Foundry<br/>Project]
            AMD[AI Model<br/>Deployment]
        end
        
        subgraph "BYOR Services (Module-Created)"
            KV[Key Vault]
            SA[Storage Account]
            CDB[Cosmos DB]
            AIS[AI Search]
        end
        
        subgraph "Supporting Services"
            LAW[Log Analytics<br/>Workspace]
            RA[Role<br/>Assignments]
        end
    end
    
    %% Core relationships
    AF --> AFP
    AF --> AMD
    AFP --> KV
    AFP --> SA
    AFP --> CDB
    AFP --> AIS
    
    %% Supporting relationships
    LAW -.-> AF
    RA -.-> AF
    RA -.-> KV
    RA -.-> SA
    RA -.-> CDB
    RA -.-> AIS
    
    %% Public access (no private endpoints)
    INTERNET[Internet] -.-> AF
    INTERNET -.-> KV
    INTERNET -.-> SA
    INTERNET -.-> CDB
    INTERNET -.-> AIS
    
    classDef required fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef byor fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef support fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef access fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    
    class AF,AFP,AMD required
    class KV,SA,CDB,AIS byor
    class LAW,RA support
    class INTERNET access
```

**Components:**
- 🔷 **Core AI Foundry** (Account, Project, Model Deployment)
- 🔶 **BYOR Services** created by the module (Key Vault, Storage, Cosmos DB, AI Search)
- 🔸 **Supporting Services** (Log Analytics, Role Assignments)
- 🔷 **Public Access** - All services accessible from the internet

This configuration provides a complete AI Foundry setup with supporting services while maintaining public accessibility for simplified access patterns.
