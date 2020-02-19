locals {
  component   = var.component
  server_sets = var.server_sets
  zone_id     = var.dns_zone
  key_name    = var.key_name
  key_file    = var.key_file
  image_name  = var.image_name
  environment = var.environment
  location    = var.location
  resource_group  = var.resource_group
  security_group  = var.security_group
  subnet          = var.subnet
}

#
# Create public IPs
resource azurerm_public_ip myterraformpublicip {
  name                         = "${var.user_name}-${local.server_sets[local.component]["dns_name"]}${count.index+1}-ip"
  count                        = local.server_sets[local.component]["count"]
  location                     = local.location
  resource_group_name          = local.resource_group
  allocation_method            = "Dynamic"

  tags = {
    environment = local.environment
    Owner = var.user_name
  }
}


# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
  count                     = local.server_sets[local.component]["count"]
  name                      = "${var.user_name}-${local.server_sets[local.component]["dns_name"]}-${count.index+1}-nic"
  location                  = local.location
  resource_group_name       = local.resource_group
  network_security_group_id = local.security_group
  internal_dns_name_label   = "${local.server_sets[local.component]["dns_name"]}${count.index+1}"
  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = local.subnet
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myterraformpublicip[count.index].id

  }

  tags = {
    environment = local.environment
    Owner = var.user_name
  }
}

locals {
    storagetemp = split(":", var.image_name)
}

# Create virtual machine
resource "azurerm_virtual_machine" "myvm" {
  count        = local.server_sets[local.component]["count"]
  name         = "${local.server_sets[local.component]["dns_name"]}${count.index+1}-${var.user_name}"
  location              = local.location
  resource_group_name   = local.resource_group
  network_interface_ids = [azurerm_network_interface.myterraformnic[count.index].id]
  vm_size               = local.server_sets[local.component]["size"]

  storage_os_disk {
    name              = "myOsDisk${local.server_sets[local.component]["dns_name"]}${count.index+1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
#    managed_disk_type = "Premium_LRS"
    # Azure won't allow different size from what belongs to specific VM size
#    disk_size_gb      = local.server_sets[local.component]["volume_size"]
  }
  storage_image_reference {
    publisher = local.storagetemp[0]
    offer     = local.storagetemp[1]
    sku       = local.storagetemp[2]
    version   = local.storagetemp[3]
  }

  os_profile {
    computer_name  = "${local.server_sets[local.component]["dns_name"]}${count.index+1}"
    admin_username = "centos"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/centos/.ssh/authorized_keys"
      key_data = file(var.key_file)
    }
  }
  boot_diagnostics {
    enabled = "false"
    storage_uri = ""
  }

  tags = {
    Owner = var.user_name
    environment = local.environment
  }
}

data azurerm_public_ip myterraformpublicip {
  depends_on = [azurerm_virtual_machine.myvm]
  name                         = "${var.user_name}-${local.server_sets[local.component]["dns_name"]}${count.index+1}-ip"
  count                        = local.server_sets[local.component]["count"]
  resource_group_name          = local.resource_group
}

data "azurerm_network_interface" "myterraformnic" {
  depends_on = [azurerm_virtual_machine.myvm]
  count = local.server_sets[local.component]["count"]
  name = "${var.user_name}-${local.server_sets[local.component]["dns_name"]}-${count.index+1}-nic"
  resource_group_name = local.resource_group
}

resource "aws_route53_record" "this" {
  zone_id = local.zone_id
  count   = local.server_sets[local.component]["count"]
  name    = "${local.server_sets[local.component]["dns_name"]}${count.index+1}.${var.name_prefix}.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [data.azurerm_public_ip.myterraformpublicip[count.index].ip_address]
}

// A variable for extracting the internal ip of the instance
output "ip" {
  value = data.azurerm_network_interface.myterraformnic.*.private_ip_address
}
// A variable for extracting the hostname of the instance
output "hostname" {
  value = aws_route53_record.this.*.fqdn
}
