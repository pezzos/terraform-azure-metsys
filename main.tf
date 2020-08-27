################################################
# FIRST PART: Creating a simple resource group
################################################

# https://www.terraform.io/docs/providers/azurerm/r/resource_group.html
# uncomment the following block
# resource "azurerm_resource_group" "example" {
#   name     = "example"
#   location = "France Central"
# }

################################################
# SECOND PART: Updating the infrastructure
################################################

# https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html
# uncomment the following block
# Example based on https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html#storage_image_reference

# resource "azurerm_virtual_network" "example" {
#   name                = "vnet-example-fc-01"
#   address_space       = ["10.0.0.0/16"]
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
# }

# resource "azurerm_subnet" "internal" {
#   name                 = "snet-example-fc-01"
#   resource_group_name  = azurerm_resource_group.example.name
#   virtual_network_name = azurerm_virtual_network.example.name
#   address_prefix       = "10.0.2.0/24"
# }

# resource "azurerm_network_interface" "example" {
#   name                = "vm-example-nic"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name

#   ip_configuration {
#     name                          = "testconfiguration1"
#     subnet_id                     = azurerm_subnet.internal.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# resource "azurerm_virtual_machine" "example" {
#   name                  = "vm-example-vm"
#   location              = azurerm_resource_group.example.location
#   resource_group_name   = azurerm_resource_group.example.name
#   network_interface_ids = [azurerm_network_interface.example.id]
#   vm_size               = "Standard_DS1_v2"

#   storage_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "16.04-LTS"
#     version   = "latest"
#   }
#   storage_os_disk {
#     name              = "myosdisk1"
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     managed_disk_type = "Standard_LRS"
#   }
#   os_profile {
#     computer_name  = "hostname"
#     admin_username = "testadmin"
#     admin_password = "Password1234!"
#   }
#   os_profile_linux_config {
#     disable_password_authentication = false
#   }
#   tags = {
#     environment = "staging"
#   }
# }