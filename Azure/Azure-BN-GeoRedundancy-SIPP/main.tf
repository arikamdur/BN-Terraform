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
resource "azurerm_resource_group" "region1_rg" {
  name     = "region1-rg-bn"
  location = var.region1
}

resource "azurerm_resource_group" "region2_rg" {
  name     = "region2-rg-bn"
  location = var.region2
}

resource "azurerm_availability_set" "region1_bn_aset" {
  name                = "region1_bn-aset"
  location            = azurerm_resource_group.region1_rg.location
  resource_group_name = azurerm_resource_group.region1_rg.name
}

resource "azurerm_availability_set" "region2_bn_aset" {
  name                = "region2_bn-aset"
  location            = azurerm_resource_group.region2_rg.location
  resource_group_name = azurerm_resource_group.region2_rg.name
}

# Generate random text for a unique storage account name
resource "random_id" "region1_randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.region1_rg.location
  }

  byte_length = 2
}

# Generate random text for a unique storage account name
resource "random_id" "region2_randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.region2_rg.location
  }

  byte_length = 2
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "region1_mystorageaccount" {
  name                     = "diag${random_id.region1_randomId.hex}"
  resource_group_name      = azurerm_resource_group.region1_rg.name
  location                 = azurerm_resource_group.region1_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "region2_mystorageaccount" {
  name                     = "diag${random_id.region2_randomId.hex}"
  resource_group_name      = azurerm_resource_group.region2_rg.name
  location                 = azurerm_resource_group.region2_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a Virtual Network
resource "azurerm_virtual_network" "region1_vnet" {
  name                = "region1-vnet"
  location            = azurerm_resource_group.region1_rg.location
  address_space       = ["${var.region1_address_space}"]
  resource_group_name = azurerm_resource_group.region1_rg.name
}

# Create a Virtual Network
resource "azurerm_virtual_network" "region2_vnet" {
  name                = "region2-vnet"
  location            = azurerm_resource_group.region2_rg.location
  address_space       = ["${var.region2_address_space}"]
  resource_group_name = azurerm_resource_group.region2_rg.name
}


resource "azurerm_subnet" "region1_public_subnet" {
  name                 = "Region1-BN-Public-Subnet"
  virtual_network_name = azurerm_virtual_network.region1_vnet.name
  resource_group_name  = azurerm_resource_group.region1_rg.name
  address_prefixes     = ["${var.region1_public_prefix}"]
}

resource "azurerm_subnet" "region2_public_subnet" {
  name                 = "Region2-BN-Public-Subnet"
  virtual_network_name = azurerm_virtual_network.region2_vnet.name
  resource_group_name  = azurerm_resource_group.region2_rg.name
  address_prefixes     = ["${var.region2_public_prefix}"]
}

resource "azurerm_subnet" "region1_private_subnet" {
  name                 = "Region1-BN-Private-Subnet"
  virtual_network_name = azurerm_virtual_network.region1_vnet.name
  resource_group_name  = azurerm_resource_group.region1_rg.name
  address_prefixes     = ["${var.region1_private_prefix}"]
}

resource "azurerm_subnet" "region2_private_subnet" {
  name                 = "Region2-BN-Private-Subnet"
  virtual_network_name = azurerm_virtual_network.region2_vnet.name
  resource_group_name  = azurerm_resource_group.region2_rg.name
  address_prefixes     = ["${var.region2_private_prefix}"]
}

resource "azurerm_subnet" "region1_mgmt_subnet" {
  name                 = "Region1-BN-MGMT-Subnet"
  virtual_network_name = azurerm_virtual_network.region1_vnet.name
  resource_group_name  = azurerm_resource_group.region1_rg.name
  address_prefixes     = ["${var.region1_mgmt_prefix}"]
}

resource "azurerm_subnet" "region2_mgmt_subnet" {
  name                 = "Region2-BN-MGMT-Subnet"
  virtual_network_name = azurerm_virtual_network.region2_vnet.name
  resource_group_name  = azurerm_resource_group.region2_rg.name
  address_prefixes     = ["${var.region2_mgmt_prefix}"]
}

resource "azurerm_network_security_group" "region1_bn_sg" {
  name                = "Region1-bn-sg"
  location            = var.region1
  resource_group_name = azurerm_resource_group.region1_rg.name

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

  security_rule {
    name                       = "Internal"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = ["${var.region1_address_space}", "${var.region2_address_space}"]
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "region2_bn_sg" {
  name                = "Region2-bn-sg"
  location            = var.region2
  resource_group_name = azurerm_resource_group.region2_rg.name

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
  security_rule {
    name                       = "Internal"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = ["${var.region1_address_space}", "${var.region2_address_space}"]
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_interface" "region1_mgmt_int" {
  name                = "region1-mgmt-int"
  location            = var.region1
  resource_group_name = azurerm_resource_group.region1_rg.name

  ip_configuration {
    name                          = "region1_mgmt_int_ipconfig"
    subnet_id                     = azurerm_subnet.region1_mgmt_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.region1_mgmt_pip.id
  }
}

resource "azurerm_network_interface" "region2_mgmt_int" {
  name                = "region2-mgmt-int"
  location            = var.region2
  resource_group_name = azurerm_resource_group.region2_rg.name

  ip_configuration {
    name                          = "region2_mgmt_int_ipconfig"
    subnet_id                     = azurerm_subnet.region2_mgmt_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.region2_mgmt_pip.id
  }
}

resource "azurerm_network_interface" "region1_public_int" {
  name                = "region1-public-int"
  location            = var.region1
  resource_group_name = azurerm_resource_group.region1_rg.name

  ip_configuration {
    name                          = "region1_public_int_ipconfig"
    subnet_id                     = azurerm_subnet.region1_public_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "region2_public_int" {
  name                = "region2-public-int"
  location            = var.region2
  resource_group_name = azurerm_resource_group.region2_rg.name

  ip_configuration {
    name                          = "region2_public_int_ipconfig"
    subnet_id                     = azurerm_subnet.region2_public_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "region1_private_int" {
  name                = "region1-private-int"
  location            = var.region1
  resource_group_name = azurerm_resource_group.region1_rg.name

  ip_configuration {
    name                          = "region1_private_int_ipconfig"
    subnet_id                     = azurerm_subnet.region1_private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "region2_private_int" {
  name                = "region2-private-int"
  location            = var.region2
  resource_group_name = azurerm_resource_group.region2_rg.name

  ip_configuration {
    name                          = "region2_private_int_ipconfig"
    subnet_id                     = azurerm_subnet.region2_private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "sipp_public_int" {
  name                = "sipp-public-int"
  location            = var.region1
  resource_group_name = azurerm_resource_group.region1_rg.name

  ip_configuration {
    name                          = "sipp_public_int_ipconfig"
    subnet_id                     = azurerm_subnet.region1_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sipp_pip.id
  }
}

resource "azurerm_network_interface" "sipp_private_int" {
  name                = "sipp_private_int"
  location            = var.region1
  resource_group_name = azurerm_resource_group.region1_rg.name

  ip_configuration {
    name                          = "sipp_private_int_ipconfig"
    subnet_id                     = azurerm_subnet.region1_private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "mgmt_sg_assoc" {
  network_interface_id      = azurerm_network_interface.region1_mgmt_int.id
  network_security_group_id = azurerm_network_security_group.region1_bn_sg.id
}

resource "azurerm_network_interface_security_group_association" "public_sg_assoc" {
  network_interface_id      = azurerm_network_interface.region1_public_int.id
  network_security_group_id = azurerm_network_security_group.region1_bn_sg.id
}

resource "azurerm_network_interface_security_group_association" "sipp_public_sg_assoc" {
  network_interface_id      = azurerm_network_interface.sipp_public_int.id
  network_security_group_id = azurerm_network_security_group.region1_bn_sg.id
}

resource "azurerm_network_interface_security_group_association" "private_sg_assoc" {
  network_interface_id      = azurerm_network_interface.region1_private_int.id
  network_security_group_id = azurerm_network_security_group.region1_bn_sg.id
}

resource "azurerm_network_interface_security_group_association" "sipp_private_sg_assoc" {
  network_interface_id      = azurerm_network_interface.sipp_private_int.id
  network_security_group_id = azurerm_network_security_group.region1_bn_sg.id
}



# Every Azure Virtual Machine comes with a private IP address. You can also 
# optionally add a public IP address for Internet-facing applications 
resource "azurerm_public_ip" "region1_mgmt_pip" {
  name                = "region1-mgmt-ip"
  location            = var.region1
  resource_group_name = azurerm_resource_group.region1_rg.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "region2_mgmt_pip" {
  name                = "region2-mgmt-ip"
  location            = var.region2
  resource_group_name = azurerm_resource_group.region2_rg.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "sipp_pip" {
  name                = "sipp-pip"
  location            = var.region1
  resource_group_name = azurerm_resource_group.region1_rg.name
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_peering" "region1_peering" {
  name                      = "Region1-Peering"
  resource_group_name       = azurerm_resource_group.region1_rg.name
  virtual_network_name      = azurerm_virtual_network.region1_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.region2_vnet.id
}

resource "azurerm_virtual_network_peering" "region2_peering" {
  name                      = "Region2-Peering"
  resource_group_name       = azurerm_resource_group.region2_rg.name
  virtual_network_name      = azurerm_virtual_network.region2_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.region1_vnet.id
}

resource "azurerm_image" "region1_bn_image" {
  name                = "region1-bn-image"
  location            = var.region1
  resource_group_name = azurerm_resource_group.region1_rg.name

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.region1_os_disk
  }
  data_disk {
    lun      = "0"
    blob_uri = var.region1_data_disk
  }
}

resource "azurerm_image" "region2_bn_image" {
  name                = "region2-bn-image"
  location            = var.region2
  resource_group_name = azurerm_resource_group.region2_rg.name

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.region2_os_disk
  }
  data_disk {
    lun      = "0"
    blob_uri = var.region2_data_disk
  }
}

resource "azurerm_virtual_machine" "region1_bn" {
  name                = "Region1-Enghouse-BorderNet-SBC"
  location            = var.region1
  availability_set_id = azurerm_availability_set.region1_bn_aset.id
  resource_group_name = azurerm_resource_group.region1_rg.name
  vm_size             = var.vm_size

  network_interface_ids         = ["${azurerm_network_interface.region1_mgmt_int.id}", "${azurerm_network_interface.region1_public_int.id}", "${azurerm_network_interface.region1_private_int.id}"]
  primary_network_interface_id  = azurerm_network_interface.region1_mgmt_int.id
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    id = azurerm_image.region1_bn_image.id
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
    storage_uri = azurerm_storage_account.region1_mystorageaccount.primary_blob_endpoint
  }
}

resource "azurerm_virtual_machine" "region2_bn" {
  name                = "Region2-Enghouse-BorderNet-SBC"
  location            = var.region2
  availability_set_id = azurerm_availability_set.region2_bn_aset.id
  resource_group_name = azurerm_resource_group.region2_rg.name
  vm_size             = var.vm_size

  network_interface_ids         = ["${azurerm_network_interface.region2_mgmt_int.id}", "${azurerm_network_interface.region2_public_int.id}", "${azurerm_network_interface.region2_private_int.id}"]
  primary_network_interface_id  = azurerm_network_interface.region2_mgmt_int.id
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    id = azurerm_image.region2_bn_image.id
  }

  storage_os_disk {
    name              = "bn-osdisk"
    managed_disk_type = "StandardSSD_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "bn2"
    admin_username = "sysadmin"
    admin_password = "Dia10gic"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.region2_mystorageaccount.primary_blob_endpoint
  }
}

resource "azurerm_linux_virtual_machine" "sipp" {
  name                = "sipp"
  location            = var.region1
  availability_set_id = azurerm_availability_set.region1_bn_aset.id
  resource_group_name = azurerm_resource_group.region1_rg.name
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
    storage_account_uri = azurerm_storage_account.region1_mystorageaccount.primary_blob_endpoint
  }
  computer_name                   = "sipp-vm"
  admin_username                  = var.sipp_username
  admin_password                  = var.sipp_password
  disable_password_authentication = false
  custom_data                     = filebase64("sipp-user-data.sh")
}



output "REGION1_BN_MGMT_IP" {
  description = "Contains the public IP address"
  value       = "https://${azurerm_public_ip.region1_mgmt_pip.ip_address}/"
}

output "REGION2_BN_MGMT_IP" {
  description = "Contains the public IP address"
  value       = "https://${azurerm_public_ip.region2_mgmt_pip.ip_address}/"
}

output "REGION1_BN_Private_Utility" {
  description = "Contains the Private IP address of BN1"
  value       = azurerm_network_interface.region1_public_int.private_ip_address
}

output "REGION2_BN_Private_Utility" {
  description = "Contains the Private IP address of BN2"
  value       = azurerm_network_interface.region2_public_int.private_ip_address
}

output "SIPP_MGMT_IP" {
  description = "Contains the public IP address"
  value       = azurerm_public_ip.sipp_pip.ip_address
}