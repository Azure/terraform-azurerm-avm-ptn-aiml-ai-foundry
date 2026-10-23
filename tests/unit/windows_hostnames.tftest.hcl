mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}
mock_provider "azurerm" {}
mock_provider "random" {}
mock_provider "time" {}

run "private_windows_hostnames_respect_guest_limits" {
  command = apply

  module {
    source = "./tests/fixtures/windows_hostnames"
  }

  assert {
    condition = alltrue([
      for name in values(output.computer_names) :
      name == null ? false : (
        length(name) >= 1 && length(name) <= 15 &&
        can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", name)) &&
        !can(regex("^[0-9]+$", name))
      )
    ])
    error_message = "Every private Windows VM must have a valid guest computer name of at most fifteen characters."
  }

  assert {
    condition = (
      output.resource_names["private-byor"] == "vm-pribyor-bej2j" &&
      length(output.resource_names["private-byor"]) == 16 &&
      output.computer_names["private-byor"] == "vm-pribyo-bej2j"
    )
    error_message = "The failing CI name must remain a sixteen-character Azure resource name while its guest hostname is safely shortened with the unique suffix intact."
  }

  assert {
    condition = alltrue([
      for example, suffix in output.example_suffixes :
      regex("base_name\\s*=\\s*\"([^\"]+)\"", file("${path.cwd}/examples/${example}/main.tf"))[0] == suffix &&
      can(regex("computer_name\\s*=\\s*module\\.naming\\.names\\.virtual_machine_windows\\.name_unique", file("${path.cwd}/examples/${example}/main.tf"))) &&
      can(regex("\\bname\\s*=\\s*module\\.naming\\.names\\.compute_virtual_machine\\.name_unique", file("${path.cwd}/examples/${example}/main.tf")))
    ])
    error_message = "All three Windows examples must use the tested suffix and separate the canonical Windows hostname from the Azure VM resource name."
  }
}
