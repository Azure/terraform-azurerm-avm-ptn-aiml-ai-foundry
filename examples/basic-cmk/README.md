# Basic CMK (Customer-Managed Key) Encryption Example

This example demonstrates how to deploy an AI Foundry account with customer-managed key (CMK) encryption using a user-assigned managed identity (UAMI).

## Overview

The example creates:

1. **User-Assigned Managed Identity (UAMI)** - Used to access the Key Vault key
2. **Key Vault** - Stores the encryption key with RBAC authorization and purge protection
3. **Key Vault Key** - RSA 2048-bit key for encryption
4. **AI Foundry Account** - Deployed with CMK encryption
5. **Role Assignment** - Grants the UAMI "Key Vault Crypto User" role on the Key Vault

## Deployment Flow

The deployment follows a specific order to ensure CMK encryption works correctly:

1. Create Key Vault, Key, and User-Assigned Managed Identity
2. Deploy AI Foundry account (initially without CMK)
3. Assign "Key Vault Crypto User" role to the UAMI
4. Update AI Foundry account to apply CMK encryption

This two-step approach is necessary because the AI Foundry account must exist before CMK encryption can be configured.

## Key Features

- **Customer-Managed Keys**: Full control over encryption keys
- **User-Assigned Managed Identity**: Secure authentication to Key Vault
- **RBAC Authorization**: Key Vault uses Azure RBAC instead of access policies
- **Purge Protection**: Prevents accidental key deletion
- **Automatic Key Version**: Uses the latest key version if not specified

## Requirements

- Azure subscription with permissions to create resources
- Terraform >= 1.9
- AzAPI provider ~> 2.0
- Azure provider ~> 4.0

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Important Notes

- The Key Vault must have RBAC authorization enabled
- Purge protection is required for production use
- The UAMI must have "Key Vault Crypto User" role before CMK can be applied
- A 60-second wait is included for RBAC propagation

## Clean Up

```bash
terraform destroy
```

The example includes automatic purge of soft-deleted AI Foundry accounts.
