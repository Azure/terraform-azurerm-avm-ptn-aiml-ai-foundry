###############################################################################
# Optional workload-owned private DNS zones
#
# Only created when create_private_dns_zones = true, which is intended for a
# sandbox or greenfield subscription with no hub, no delegated platform zones
# and no DNS policy.
#
# In a real enterprise-scale landing zone leave this disabled: private DNS is a
# platform responsibility, and a second copy of privatelink.* in a spoke causes
# split-brain resolution that is painful to unpick later.
###############################################################################

resource "azurerm_private_dns_zone" "this" {
  for_each = var.create_private_dns_zones ? local.private_dns_zone_names : {}

  name                = each.value
  resource_group_name = local.resource_group_name
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = var.manage_private_dns_zone_groups
      error_message = "create_private_dns_zones requires manage_private_dns_zone_groups = true, otherwise the zones are created but never attached to any private endpoint."
    }
  }
  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = local.private_dns_zone_links

  name                  = each.value.link_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.value.zone_key].name
  resource_group_name   = local.resource_group_name
  registration_enabled  = false
  tags                  = var.tags
  virtual_network_id    = each.value.virtual_network_resource_id
}
