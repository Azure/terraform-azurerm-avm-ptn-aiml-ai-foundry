# User-assigned identities example

This deploys one user-assigned managed identity and attaches it to both the AI Foundry account and two projects. One project uses only the user-assigned identity; the other uses both system-assigned and user-assigned identities.

## Plan-known identity aliases

The identity is created in the same deployment. The account and both projects
reference it through the stable `application` alias, while its Azure ID remains
an apply-time value. No GUID map keys or staged/targeted applies are needed.