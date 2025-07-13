resource "azurerm_private_endpoint" "this" {
  for_each = { for k, v in var.private_endpoints : k => v if var.private_endpoints_manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pep-${var.ai_foundry_name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.ai_foundry_name}"
    private_connection_resource_id = azapi_resource.ai_foundry.id
    subresource_names              = ["account"]
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = "account"
      subresource_name   = "account"
    }
  }
  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }
}

resource "azurerm_private_endpoint" "this_unmanaged_dns_zone_groups" {
  for_each = { for k, v in var.private_endpoints : k => v if !var.private_endpoints_manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pep-${var.ai_foundry_name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.ai_foundry_name}"
    private_connection_resource_id = azapi_resource.ai_foundry.id
    subresource_names              = ["account"]
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = "account"
      subresource_name   = "account"
    }
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
}

locals {
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
}

resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each = local.private_endpoint_application_security_group_associations

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this[each.value.pe_key].id : azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.value.pe_key].id
}

# Role assignments for private endpoints
resource "azurerm_role_assignment" "private_endpoint_this" {
  for_each = local.private_endpoint_role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this[each.value.pe_key].id : azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.value.pe_key].id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

locals {
  private_endpoint_role_assignments = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for ra_k, ra_v in pe_v.role_assignments : {
        ra_key                                 = ra_k
        pe_key                                 = pe_k
        role_definition_id_or_name             = ra_v.role_definition_id_or_name
        principal_id                           = ra_v.principal_id
        description                            = ra_v.description
        skip_service_principal_aad_check       = ra_v.skip_service_principal_aad_check
        condition                              = ra_v.condition
        condition_version                      = ra_v.condition_version
        delegated_managed_identity_resource_id = ra_v.delegated_managed_identity_resource_id
        principal_type                         = ra_v.principal_type
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.ra_key}" => assoc }

  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions/"
}

# Private endpoint locks
resource "azurerm_management_lock" "private_endpoint_this" {
  for_each = {
    for pe_k, pe_v in var.private_endpoints : pe_k => pe_v.lock
    if pe_v.lock != null
  }

  lock_level = each.value.kind
  name       = coalesce(each.value.name, "lock-${each.key}")
  scope      = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this[each.key].id : azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.key].id
  notes      = each.value.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}
