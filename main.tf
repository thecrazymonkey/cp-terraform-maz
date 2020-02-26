# simple terraform to creat CP cluster within AWS, software provisioning to be done via cp-ansible

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

# use aws for DNS
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  profile = "confluentsa"
}

# Configure the Microsoft Azure Provider - provide via ARM_ evironment variables
# see here on how to set them - https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure
provider "azurerm" {
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
  name     = "${var.user_name}-cprg"
  location = var.region

  tags = {
    environment = var.environment
    Owner =  var.user_name
  }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "${var.user_name}-cpnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  tags = {
    environment = var.environment
    Owner =  var.user_name
  }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "${var.user_name}-cpsubnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefix       = "10.0.1.0/24"
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "${var.user_name}-cpnsg"
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = format("%s/32",chomp(data.http.myip.body))
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Zookeeper"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2181"
    source_address_prefix      = format("%s/32",chomp(data.http.myip.body))
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Broker"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9091-9094"
    source_address_prefix      = format("%s/32",chomp(data.http.myip.body))
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SR_Connect_KSQL"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8081-8083"
    source_address_prefix      = format("%s/32",chomp(data.http.myip.body))
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "KSQL"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8088"
    source_address_prefix      = format("%s/32",chomp(data.http.myip.body))
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "C3"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9021"
    source_address_prefix      = format("%s/32",chomp(data.http.myip.body))
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "JMX"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9999"
    source_address_prefix      = format("%s/32",chomp(data.http.myip.body))
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "JMX_Exporter"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = format("%s/32",chomp(data.http.myip.body))
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Prometheus"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = format("%s/32",chomp(data.http.myip.body))
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment
    Owner = var.user_name
  }
}

module "cp_maz_zk" {
  source      = "./cp-component"
  component   = "zk"
  server_sets = var.server_sets
  image_name  = var.image_name
  key_name    = var.key_name
  key_file    = var.key_file
  domain_name = var.domain_name
  name_prefix = var.name_prefix
  dns_zone    = var.dns_zone
  user_name   = var.user_name
  environment = var.environment
  location    = azurerm_resource_group.myterraformgroup.location
  resource_group  = azurerm_resource_group.myterraformgroup.name
  security_group  = azurerm_network_security_group.myterraformnsg.id
  subnet          = azurerm_subnet.myterraformsubnet.id
}

module "cp_maz_bk" {
  source      = "./cp-component"
  component   = "broker"
  server_sets = var.server_sets
  image_name  = var.image_name
  key_name    = var.key_name
  key_file    = var.key_file
  domain_name = var.domain_name
  name_prefix = var.name_prefix
  dns_zone    = var.dns_zone
  user_name   = var.user_name
  environment = var.environment
  location    = azurerm_resource_group.myterraformgroup.location
  resource_group  = azurerm_resource_group.myterraformgroup.name
  security_group  = azurerm_network_security_group.myterraformnsg.id
  subnet          = azurerm_subnet.myterraformsubnet.id
}

module "cp_maz_co" {
  source      = "./cp-component"
  component   = "connect"
  server_sets = var.server_sets
  image_name  = var.image_name
  key_name    = var.key_name
  key_file    = var.key_file
  domain_name = var.domain_name
  name_prefix = var.name_prefix
  dns_zone    = var.dns_zone
  user_name   = var.user_name
  environment = var.environment
  location    = azurerm_resource_group.myterraformgroup.location
  resource_group  = azurerm_resource_group.myterraformgroup.name
  security_group  = azurerm_network_security_group.myterraformnsg.id
  subnet          = azurerm_subnet.myterraformsubnet.id
}
module "cp_maz_rp" {
  source      = "./cp-component"
  component   = "restproxy"
  server_sets = var.server_sets
  image_name  = var.image_name
  key_name    = var.key_name
  key_file    = var.key_file
  domain_name = var.domain_name
  name_prefix = var.name_prefix
  dns_zone    = var.dns_zone
  user_name   = var.user_name
  environment = var.environment
  location    = azurerm_resource_group.myterraformgroup.location
  resource_group  = azurerm_resource_group.myterraformgroup.name
  security_group  = azurerm_network_security_group.myterraformnsg.id
  subnet          = azurerm_subnet.myterraformsubnet.id
}
module "cp_maz_sr" {
  source      = "./cp-component"
  component   = "schemaregistry"
  server_sets = var.server_sets
  image_name  = var.image_name
  key_name    = var.key_name
  key_file    = var.key_file
  domain_name = var.domain_name
  name_prefix = var.name_prefix
  dns_zone    = var.dns_zone
  user_name   = var.user_name
  environment = var.environment
  location    = azurerm_resource_group.myterraformgroup.location
  resource_group  = azurerm_resource_group.myterraformgroup.name
  security_group  = azurerm_network_security_group.myterraformnsg.id
  subnet          = azurerm_subnet.myterraformsubnet.id
}

module "cp_maz_ks" {
  source      = "./cp-component"
  component   = "ksql"
  server_sets = var.server_sets
  image_name  = var.image_name
  key_name    = var.key_name
  key_file    = var.key_file
  domain_name = var.domain_name
  name_prefix = var.name_prefix
  dns_zone    = var.dns_zone
  user_name   = var.user_name
  environment = var.environment
  location    = azurerm_resource_group.myterraformgroup.location
  resource_group  = azurerm_resource_group.myterraformgroup.name
  security_group  = azurerm_network_security_group.myterraformnsg.id
  subnet          = azurerm_subnet.myterraformsubnet.id
}

module "cp_maz_cc" {
  source      = "./cp-component"
  component   = "controlcenter"
  server_sets = var.server_sets
  image_name  = var.image_name
  key_name    = var.key_name
  key_file    = var.key_file
  domain_name = var.domain_name
  name_prefix = var.name_prefix
  dns_zone    = var.dns_zone
  user_name   = var.user_name
  environment = var.environment
  location    = azurerm_resource_group.myterraformgroup.location
  resource_group  = azurerm_resource_group.myterraformgroup.name
  security_group  = azurerm_network_security_group.myterraformnsg.id
  subnet          = azurerm_subnet.myterraformsubnet.id
}
