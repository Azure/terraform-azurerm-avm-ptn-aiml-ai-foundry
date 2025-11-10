## Notes

- This example creates a Key Vault, User Assigned Identity, and configures CMK for AI Foundry
- The User Assigned Identity is granted Key Vault Crypto Service Encryption User role
- The Key Vault access policy allows the identity to perform cryptographic operations
- CMK encryption is applied to the AI Foundry account for data at rest
