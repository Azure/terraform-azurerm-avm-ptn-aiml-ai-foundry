# Multiple Projects Example

This example demonstrates how to use the AI Foundry module to create multiple AI projects within a single deployment. This is useful for scenarios where you need separate environments (dev, test, prod) or different project contexts within the same AI Foundry infrastructure.

## Features Demonstrated

- **Multiple Projects**: Creates multiple AI Foundry projects using the `ai_services_projects` variable
- **Custom Project Configuration**: Each project can have its own description and display name
- **Backward Compatibility**: The module maintains compatibility with existing single-project deployments

## Usage

The key feature is the `ai_services_projects` variable which allows you to define multiple projects:

```hcl
ai_services_projects = {
  "dev" = {
    description  = "Development environment for AI workloads"
    display_name = "Development AI Project"
  }
  "test" = {
    description  = "Testing environment for AI workloads"
    display_name = "Testing AI Project"
  }
  "prod" = {
    description  = "Production environment for AI workloads"
    display_name = "Production AI Project"
  }
}
```

## Outputs

When using multiple projects, the module provides both backward-compatible single project outputs and new map-based outputs:

- **Single Project Outputs** (for backward compatibility):
  - `ai_foundry_project_id` - Returns the "default" project or the first project if no default exists
  - `ai_foundry_project_name` - Returns the name of the default/first project
  - `resource_id` - Returns the resource ID of the default/first project

- **Multiple Projects Outputs**:
  - `ai_foundry_project_ids` - Map of all project keys to their resource IDs
  - `ai_foundry_project_names` - Map of all project keys to their names
  - `resource_ids` - Map of all project keys to their resource IDs

## Project Naming

Projects are automatically named using the pattern:
- For the "default" project (when using old single-project variables): Uses the configured resource name
- For named projects: `aif-{base_name}-{project_key}-{random_token}`

## Backward Compatibility

The module maintains full backward compatibility. Existing deployments using the old `ai_foundry_project_description` variable will continue to work unchanged. When no `ai_services_projects` are specified, the module automatically creates a single "default" project using the existing configuration.

## Running This Example

```bash
terraform init
terraform plan
terraform apply
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9, < 2.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5 |