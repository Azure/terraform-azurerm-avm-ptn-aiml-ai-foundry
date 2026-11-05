mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}
mock_provider "tls" {}

override_module {
  target = module.private_byor
  outputs = {
    agent_capability_host_ids = {
      account = "account-host"
      project = "project-host"
    }
  }
}

run "module_owned_example_exposes_both_hosts" {
  command = plan

  module {
    source = "./examples/module-owned-agent-host"
  }

  assert {
    condition = (
      output.agent_capability_host_ids.account == "account-host" &&
      output.agent_capability_host_ids.project == "project-host"
    )
    error_message = "The module-owned example must expose both delegated host IDs."
  }
}

run "module_owned_example_rejects_missing_account_host" {
  command = plan

  module {
    source = "./examples/module-owned-agent-host"
  }

  override_module {
    target = module.private_byor
    outputs = {
      agent_capability_host_ids = {
        account = null
        project = "project-host"
      }
    }
  }

  expect_failures = [output.agent_capability_host_ids]
}

run "module_owned_example_rejects_missing_project_host" {
  command = plan

  module {
    source = "./examples/module-owned-agent-host"
  }

  override_module {
    target = module.private_byor
    outputs = {
      agent_capability_host_ids = {
        account = "account-host"
        project = null
      }
    }
  }

  expect_failures = [output.agent_capability_host_ids]
}
