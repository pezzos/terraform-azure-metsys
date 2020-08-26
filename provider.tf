# https://www.terraform.io/docs/providers/index.html

# Configure the Terraform's backend with Azure Storage Account
# more info: https://www.terraform.io/docs/backends/types/azurerm.html
terraform {
  backend "azurerm" {
    resource_group_name = "<RESOURCEGROUP>"
    storage_account_name = "<ACCOUNTNAME>"
    container_name = "<CONTAINERNAME>"
    key = "<PROJECTNAME>.tfstate"
  }
}

# Configure the Azure Provider
# more info and lastest version number: https://github.com/terraform-providers/terraform-provider-azurerm
provider "azurerm" {
  # Even if the version attribute is optional, pinning it to a given version avoid update conflict
  version = "~> 2.24"
  features {}
}