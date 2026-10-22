terraform {
  required_version = ">= 1.12, < 2.0"

  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    # tflint-ignore: terraform_unused_required_providers
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.38"
    }
    # tflint-ignore: terraform_unused_required_providers
    modtm = {
      source  = "registry.terraform.io/azure/modtm"
      version = "~> 0.3"
    }
    # tflint-ignore: terraform_unused_required_providers
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    # tflint-ignore: terraform_unused_required_providers
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}
