resource "azurerm_storage_account" "mysqlstorage" {
    name                        = "mysqlstorage01"
    resource_group_name         = azurerm_resource_group.mysql_resource.name
    location                    = azurerm_resource_group.mysql_resource.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

resource "azurerm_linux_virtual_machine" "mysql_vm" {
    name                  = "mysql_vm"
    location              = azurerm_resource_group.mysql_resource.location
    resource_group_name   = azurerm_resource_group.mysql_resource.name
    network_interface_ids = [azurerm_network_interface.mysql_network_interface.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "mysql_db_disk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "DatabaseMySQLDBserver"
    admin_username = var.user
    admin_password = var.password
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mysqlstorage.primary_blob_endpoint
    }

}

resource "time_sleep" "wait_30_seconds_db" {
  depends_on = [azurerm_linux_virtual_machine.mysql_vm]
  create_duration = "40s"
}


resource "null_resource" "upload_db" {
    provisioner "file" {
        connection {
            type = "ssh"
            user = var.user
            password = var.password
            host = azurerm_public_ip.mysql_public_ip.ip_address
        }
        source = "mysql"
        destination = format("/home/%s", var.user)
        # destination = "/home/YOURUSER"
    }

    depends_on = [ time_sleep.wait_30_seconds_db ]
}

resource "null_resource" "deploy_db" {
    triggers = {
        order = null_resource.upload_db.id
    }
    # TODO {var.user}"
    provisioner "remote-exec" {
        connection {
            type = "ssh"
            user = var.user
            password = var.password
            host = azurerm_public_ip.mysql_public_ip.ip_address
        }
        inline = [
            "sudo apt-get update",
            "sudo apt-get install -y mysql-server-5.7",
            format("sudo mysql < /home/%s/mysql/scripts/user_sa.sql", var.user),
            format("sudo cp -f /home/%s/mysql/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf", var.user),
            "sudo service mysql restart",
            "sleep 20",
        ]
    }
}