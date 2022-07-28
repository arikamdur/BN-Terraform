terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.94.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# First we'll create a resource group. In Azure every resource belongs to a 
# resource group. Think of it as a container to hold all your resources. 
# You can find a complete list of Azure resources supported by Terraform here:
# https://www.terraform.io/docs/providers/azurerm/
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_availability_set" "bn_aset" {
  name                = "bn-aset"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.location
  }

  byte_length = 2
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = azurerm_resource_group.rg.location
  address_space       = ["${var.address_space}"]
  resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_subnet" "public_subnet" {
  name                 = "BN-Public-Subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["${var.public_prefix}"]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "BN-Private-Subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["${var.private_prefix}"]
}

resource "azurerm_subnet" "mgmt_subnet" {
  name                 = "BN-MGMT-Subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["${var.mgmt_prefix}"]
}

resource "azurerm_network_security_group" "bn-sg" {
  name                = "bn-sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "public-sg" {
  name                = "public-sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Teams_Allowed_IPs"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = ["52.112.0.0/14", "52.120.0.0/14"]
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_interface" "mgmt_int" {
  name                = "mgmt_int"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "mgmt_int_ipconfig"
    subnet_id                     = azurerm_subnet.mgmt_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mgmt-pip.id
  }
}

resource "azurerm_network_interface" "public_int" {
  name                = "public_int"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "public_int_ipconfig"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-pip.id
  }
}

resource "azurerm_network_interface" "sipp_public_int" {
  name                = "sipp_public_int"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "sipp_public_int_ipconfig"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sipp-pip.id
  }
}

resource "azurerm_network_interface" "private_int" {
  name                = "private_int"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "private_int_ipconfig"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "sipp_private_int" {
  name                = "sipp_private_int"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "sipp_private_int_ipconfig"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "mgmt_sg_assoc" {
  network_interface_id      = azurerm_network_interface.mgmt_int.id
  network_security_group_id = azurerm_network_security_group.bn-sg.id
}

resource "azurerm_network_interface_security_group_association" "public_sg_assoc" {
  network_interface_id      = azurerm_network_interface.public_int.id
  network_security_group_id = azurerm_network_security_group.public-sg.id
}

resource "azurerm_network_interface_security_group_association" "sipp_public_sg_assoc" {
  network_interface_id      = azurerm_network_interface.sipp_public_int.id
  network_security_group_id = azurerm_network_security_group.bn-sg.id
}

resource "azurerm_network_interface_security_group_association" "private_sg_assoc" {
  network_interface_id      = azurerm_network_interface.private_int.id
  network_security_group_id = azurerm_network_security_group.bn-sg.id
}

resource "azurerm_network_interface_security_group_association" "sipp_private_sg_assoc" {
  network_interface_id      = azurerm_network_interface.sipp_private_int.id
  network_security_group_id = azurerm_network_security_group.bn-sg.id
}



# Every Azure Virtual Machine comes with a private IP address. You can also 
# optionally add a public IP address for Internet-facing applications 
resource "azurerm_public_ip" "mgmt-pip" {
  name                = "mgmt-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "sipp-pip" {
  name                = "sipp-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "public-pip" {
  name                = "public-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_image" "bn_image" {
  name                = "bn_image"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.os_disk
  }
  data_disk {
    lun      = "0"
    blob_uri = var.data_disk
  }


}

resource "azurerm_virtual_machine" "bn1" {
  name                = "Enghouse-BorderNet-SBC"
  location            = var.location
  availability_set_id = azurerm_availability_set.bn_aset.id
  resource_group_name = azurerm_resource_group.rg.name
  vm_size             = var.vm_size

  network_interface_ids         = ["${azurerm_network_interface.mgmt_int.id}", "${azurerm_network_interface.public_int.id}", "${azurerm_network_interface.private_int.id}"]
  primary_network_interface_id  = azurerm_network_interface.mgmt_int.id
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    id = azurerm_image.bn_image.id
  }

  storage_os_disk {
    name              = "bn-osdisk"
    managed_disk_type = "StandardSSD_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "bn1"
    admin_username = "sysadmin"
    admin_password = "Dia10gic"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }
}

resource "azurerm_linux_virtual_machine" "sipp" {
  name                = "sipp"
  location            = var.location
  availability_set_id = azurerm_availability_set.bn_aset.id
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_F2s_v2"

  network_interface_ids = ["${azurerm_network_interface.sipp_public_int.id}", "${azurerm_network_interface.sipp_private_int.id}"]
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }


  os_disk {
    name                 = "sipp-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }
  computer_name                   = "sipp-vm"
  admin_username                  = var.sipp_username
  admin_password                  = var.sipp_password
  disable_password_authentication = false
  custom_data                     = filebase64("sipp-user-data.sh")
}


output "MGMT_url" {
  value = "https://${azurerm_public_ip.mgmt-pip.ip_address}/"
}

output "SIPP_IP" {
  value = azurerm_public_ip.sipp-pip.ip_address
}

output "Teams_Public_IP" {
  value = azurerm_public_ip.public-pip.ip_address
}

output "Public_ip_address" {
  value = azurerm_network_interface.public_int.private_ip_address
}

output "Private_ip_address" {
  value = azurerm_network_interface.private_int.private_ip_address
}