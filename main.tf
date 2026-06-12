resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ==========================================

# NETWORK

# ==========================================

resource "azurerm_virtual_network" "network" {
  name                = "239909-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "239909-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ==========================================

# APP PUBLIC IP

# ==========================================

resource "azurerm_public_ip" "app_public_ip" {
  name                = "239909-app-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# ==========================================

# DB PUBLIC IP

# ==========================================

resource "azurerm_public_ip" "db_public_ip" {
  name                = "239909-db-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# ==========================================

# APP NIC

# ==========================================

resource "azurerm_network_interface" "app_nic" {
  name                = "239909-app-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app_public_ip.id
  }
}

# ==========================================

# DB NIC

# ==========================================

resource "azurerm_network_interface" "db_nic" {
  name                = "239909-db-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.db_public_ip.id
  }
}

# ==========================================

# APP NSG

# ==========================================

resource "azurerm_network_security_group" "app_nsg" {
  name                = "239909-app-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "app_ssh" {
  name                       = "Allow-SSH"
  priority                   = 1001
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.app_nsg.name
}

resource "azurerm_network_security_rule" "app_backend" {
  name                       = "Allow-Backend"
  priority                   = 1002
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "5000"
  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.app_nsg.name
}

# ==========================================

# DB NSG

# ==========================================

resource "azurerm_network_security_group" "db_nsg" {
  name                = "239909-db-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "db_ssh" {
  name                       = "Allow-SSH"
  priority                   = 1001
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.db_nsg.name
}

resource "azurerm_network_security_rule" "db_postgres" {
  name                       = "Allow-Postgres"
  priority                   = 1002
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "5432"
  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.db_nsg.name
}

resource "azurerm_network_interface_security_group_association" "app_assoc" {
  network_interface_id      = azurerm_network_interface.app_nic.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_network_interface_security_group_association" "db_assoc" {
  network_interface_id      = azurerm_network_interface.db_nic.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# ==========================================

# APP VM

# ==========================================

resource "azurerm_linux_virtual_machine" "app_vm" {
  name                            = "239909-app"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.app_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ==========================================

# DB VM

# ==========================================

resource "azurerm_linux_virtual_machine" "db_vm" {
  name                            = "239909-db"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.db_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

output "app_public_ip" {
  value = azurerm_public_ip.app_public_ip.ip_address
}

output "db_public_ip" {
  value = azurerm_public_ip.db_public_ip.ip_address
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/hosts.ini"

  content = templatefile("${path.module}/inventory.tpl", {
    app_ip = azurerm_public_ip.app_public_ip.ip_address
    db_ip  = azurerm_public_ip.db_public_ip.ip_address
  })
}

resource "null_resource" "run_ansible" {

  depends_on = [
    azurerm_linux_virtual_machine.app_vm,
    azurerm_linux_virtual_machine.db_vm,
    local_file.ansible_inventory
  ]

  provisioner "local-exec" {
    command = <<EOT
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts.ini main.yml
EOT
  }
}

output "healthcheck_url" {
  value = "http://${azurerm_public_ip.app_public_ip.ip_address}:5000/api/HealthCheck/database"
}

output "healthcheck_command" {
  value = "curl http://${azurerm_public_ip.app_public_ip.ip_address}:5000/api/HealthCheck/database"
}
