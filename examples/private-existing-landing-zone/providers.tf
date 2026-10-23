provider "azurerm" {
  storage_use_azuread = true
  subscription_id     = var.subscription_id

  features {
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
    key_vault {
      purge_soft_deleted_keys_on_destroy    = false
      purge_soft_deleted_secrets_on_destroy = false
      recover_soft_deleted_key_vaults       = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azapi" {
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}
