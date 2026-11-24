###############################################################################
# Workload resource group inside the application landing zone
###############################################################################

resource "azurerm_resource_group" "this" {
  count = var.resource_group.create ? 1 : 0

  location = var.location
  name     = local.resource_group_name
  tags     = var.tags
}

data "azurerm_resource_group" "this" {
  count = var.resource_group.create ? 0 : 1

  name = local.resource_group_name
}

###############################################################################
# Landing zone networking
#
# The spoke virtual network, the private endpoint subnet, route tables, NSGs and
# peering to the hub are owned by the platform. They are consumed here, never
# created. The only subnet this configuration will optionally create is the
# delegated subnet required by the AI Foundry Standard Agent setup, because that
# delegation is workload specific.
###############################################################################

resource "azurerm_subnet" "agent" {
  count = var.agent_subnet.create ? 1 : 0

  address_prefixes     = var.agent_subnet.address_prefixes
  name                 = var.agent_subnet.name
  resource_group_name  = var.agent_subnet.virtual_network_resource_group_name
  virtual_network_name = var.agent_subnet.virtual_network_name

  delegation {
    name = "Microsoft.App.environments"

    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.App/environments"
    }
  }
}
