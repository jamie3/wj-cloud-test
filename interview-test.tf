#
# Configure the Azure Provider
#
provider "azurerm" { }

#
# Create a resource group
#
resource "azurerm_resource_group" "wj" {
  name     = "interview-test"
  location = "West US"
}

#
# Create a virtual network within the resource group
#
resource "azurerm_virtual_network" "wj" {
  name                = "wj-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.wj.location}"
  resource_group_name = "${azurerm_resource_group.wj.name}"
} 

resource "azurerm_subnet" "subnet_gateway" {
  name                 = "subnet_gateway"
  resource_group_name  = "${azurerm_resource_group.wj.name}"
  virtual_network_name = "${azurerm_virtual_network.wj.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_subnet" "subnet_trusted" {
  name                 = "subnet_trusted"
  resource_group_name  = "${azurerm_resource_group.wj.name}"
  virtual_network_name = "${azurerm_virtual_network.wj.name}"
  address_prefix       = "10.0.3.0/24"
}

resource "azurerm_subnet" "subnet_untrusted" {
  name                 = "subnet_untrusted"
  resource_group_name  = "${azurerm_resource_group.wj.name}"
  virtual_network_name = "${azurerm_virtual_network.wj.name}"
  address_prefix       = "10.0.4.0/24"
}

#
# Network Security Groups
#
resource "azurerm_network_security_group" "untrusted" {
  name                = "nsg_untrusted"
  location            = "${azurerm_resource_group.wj.location}"
  resource_group_name = "${azurerm_resource_group.wj.name}"
}

resource "azurerm_network_security_group" "trusted" {
  name                = "nsg_trusted"
  location            = "${azurerm_resource_group.wj.location}"
  resource_group_name = "${azurerm_resource_group.wj.name}"
}

resource "azurerm_network_security_group" "gateway" {
  name                = "nsg_gateway"
  location            = "${azurerm_resource_group.wj.location}"
  resource_group_name = "${azurerm_resource_group.wj.name}"
}

#
# Network Rules - Untrusted
#

# Allow SSH to untrusted subnet
resource "azurerm_network_security_rule" "r1" {
  name                        = "Allow_SSH_To_Untrusted"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.4.0/24"
  resource_group_name         = "${azurerm_resource_group.wj.name}"
  network_security_group_name = "${azurerm_network_security_group.untrusted.name}"
}

# Allow SSH from untrusted to trusted subnet
resource "azurerm_network_security_rule" "r2" {
  name                        = "Allow_SSH_To_Trusted"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "10.0.4.0/24"
  destination_address_prefix  = "10.0.3.0/24"
  resource_group_name         = "${azurerm_resource_group.wj.name}"
  network_security_group_name = "${azurerm_network_security_group.untrusted.name}"
}

# Allow SSH from untrusted to trusted subnet
resource "azurerm_network_security_rule" "r3" {
  name                        = "Allow_SSH_From_Untrusted"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "10.0.4.0/24"
  destination_address_prefix  = "10.0.3.0/24"
  resource_group_name         = "${azurerm_resource_group.wj.name}"
  network_security_group_name = "${azurerm_network_security_group.trusted.name}"
}

# Allow SSH from untrusted to trusted subnet
resource "azurerm_network_security_rule" "r4" {
  name                        = "Allow_SSH_From_Trusted_To_Gateway"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "10.0.3.0/24"
  destination_address_prefix  = "10.0.2.0/24"
  resource_group_name         = "${azurerm_resource_group.wj.name}"
  network_security_group_name = "${azurerm_network_security_group.gateway.name}"
}

#
# Virtual machine Trusted Network
#
resource "azurerm_network_interface" "trusted" {
  name                = "network_interface_trusted"
  location            = "${azurerm_resource_group.wj.location}"
  resource_group_name = "${azurerm_resource_group.wj.name}"

  ip_configuration {
    name                          = "ipconfiguration"
    subnet_id                     = "${azurerm_subnet.subnet_trusted.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_managed_disk" "trusted" {
  name                 = "managed_disk_trusted"
  location             = "${azurerm_resource_group.wj.location}"
  resource_group_name  = "${azurerm_resource_group.wj.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_virtual_machine" "wj" {
  name                  = "trusted_vm"
  location              = "${azurerm_resource_group.wj.location}"
  resource_group_name   = "${azurerm_resource_group.wj.name}"
  network_interface_ids = ["${azurerm_network_interface.trusted.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk_trusted"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.trusted.name}"
    managed_disk_id = "${azurerm_managed_disk.trusted.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.trusted.disk_size_gb}"
  }

  os_profile {
    computer_name  = "wjtrusted"
    admin_username = "Jamie"
    admin_password = "J@mieIsC@@l!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

#
# Virtual machine Untrusted Network
#

resource "azurerm_public_ip" "wj" {
  name                         = "public-ip"
  location                     = "${azurerm_resource_group.wj.location}"
  resource_group_name          = "${azurerm_resource_group.wj.name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 5
}

resource "azurerm_network_interface" "untrusted" {
  name                = "network_interface_untrusted"
  location            = "${azurerm_resource_group.wj.location}"
  resource_group_name = "${azurerm_resource_group.wj.name}"

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = "${azurerm_subnet.subnet_untrusted.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.wj.id}"
  }
}

#public_ip_address_id          = "${azurerm_public_ip.wj.id}"

resource "azurerm_managed_disk" "untrusted" {
  name                 = "managed_disk_untrusted"
  location             = "${azurerm_resource_group.wj.location}"
  resource_group_name  = "${azurerm_resource_group.wj.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_virtual_machine" "untrusted" {
  name                  = "untrusted_vm"
  location              = "${azurerm_resource_group.wj.location}"
  resource_group_name   = "${azurerm_resource_group.wj.name}"
  network_interface_ids = ["${azurerm_network_interface.untrusted.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk_untrusted"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.untrusted.name}"
    managed_disk_id = "${azurerm_managed_disk.untrusted.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.untrusted.disk_size_gb}"
  }

  os_profile {
    computer_name  = "wjuntrusted"
    admin_username = "Jamie"
    admin_password = "J@mieIsC@@l!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}