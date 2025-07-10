# Test to validate multiple projects functionality
terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Test multiple projects configuration
module "test_multiple_projects" {
  source = "../"

  base_name = "test"
  location  = "East US"
  
  ai_services_projects = {
    "proj1" = {
      description  = "Test project 1"
      display_name = "Test Project 1"
    }
    "proj2" = {
      description  = "Test project 2" 
      display_name = "Test Project 2"
    }
  }
  
  create_ai_agent_service    = false
  create_dependent_resources = false
  create_private_endpoints   = false
  create_project_connections = false
  create_resource_group      = true
}

# Test backward compatibility - single project using old variables
module "test_single_project_legacy" {
  source = "../"

  base_name = "legacy"
  location  = "East US"
  
  ai_foundry_project_description = "Legacy single project"
  
  create_ai_agent_service    = false
  create_dependent_resources = false
  create_private_endpoints   = false
  create_project_connections = false
  create_resource_group      = true
}

# Validate that outputs work correctly for multiple projects
output "multiple_projects_test" {
  value = {
    project_ids   = module.test_multiple_projects.ai_foundry_project_ids
    project_names = module.test_multiple_projects.ai_foundry_project_names
    # Should contain 2 projects: proj1 and proj2
    project_count = length(module.test_multiple_projects.ai_foundry_project_ids)
  }
}

# Validate backward compatibility
output "legacy_project_test" {
  value = {
    project_id   = module.test_single_project_legacy.ai_foundry_project_id
    project_name = module.test_single_project_legacy.ai_foundry_project_name
    # Should contain 1 project (default)
    project_count = length(module.test_single_project_legacy.ai_foundry_project_ids)
  }
}