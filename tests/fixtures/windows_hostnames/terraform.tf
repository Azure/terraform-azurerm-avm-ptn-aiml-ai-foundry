terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
