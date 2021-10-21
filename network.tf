
# FIREWALL
resource "azurerm_network_security_group" "mysql_firewall" {
    name                = "mysql_firewall"
    location            = azurerm_resource_group.mysql_resource.location
    resource_group_name = azurerm_resource_group.mysql_resource.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
 
    # NO REQUIRED 
    security_rule {
        name                       = "DEFAULT_MYSQL_PORT"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3306"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

}

# Virtual Network
resource "azurerm_virtual_network" "mysql_network" {
    name                = "mysql_network"
    address_space       = ["10.122.0.0/16"]
    location            = azurerm_resource_group.mysql_resource.location
    resource_group_name = azurerm_resource_group.mysql_resource.name
}

# Virtual Subnet 
resource "azurerm_subnet" "mysql_subnet_network" {
    name                 = "mysql_subnet_network"
    resource_group_name  = azurerm_resource_group.mysql_resource.name
    virtual_network_name = azurerm_virtual_network.mysql_network.name
    address_prefixes       = ["10.122.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "mysql_public_ip" {
    name                         = "mysql_public_ip"
    location                     = azurerm_resource_group.mysql_resource.location
    resource_group_name          = azurerm_resource_group.mysql_resource.name
    allocation_method            = "Static"
}

# network interface for VM
resource "azurerm_network_interface" "mysql_network_interface" {
    name                      = "mysql_network_interface"
    location                  = azurerm_resource_group.mysql_resource.location
    resource_group_name       = azurerm_resource_group.mysql_resource.name

    # Running local NAT
    ip_configuration {
        name                          = "mysql_NIC_config"
        subnet_id                     = azurerm_subnet.mysql_subnet_network.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.mysql_public_ip.id
    }
}

# association between network interface X firewall
resource "azurerm_network_interface_security_group_association" "net_interface_firewall" {
    network_interface_id      = azurerm_network_interface.mysql_network_interface.id
    network_security_group_id = azurerm_network_security_group.mysql_firewall.id
}
