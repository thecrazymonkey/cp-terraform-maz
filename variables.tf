# Configure the Azure Provider
variable "region" {
  default = "eastus"
}
variable "dns_zone" {
  # ps.confluent.io
  default = "Z3DYW71V76XUGV"
}

variable "user_name" {
  default = "ivan"
}

variable "environment" {
  default = "Confluent Platform"
}

variable "name_prefix" {
  default = "ivan.maz"
}
variable "key_name" {
  default = "ikunz"
}
variable "key_file" {
  default = "~/.ssh/ivan_gcp.pub"
}

variable "domain_name" {
  default = "ps.confluent.io"
}

variable "image_name" {
  default = "OpenLogic:CentOS:7.7:latest"
}

variable "server_sets" {
  description = "Describes specific settings for individual CP servers (count, type, .....)"
  default = {
    "zk" = {
        count = 3,
        size = "Standard_A1_v2",
        volume_size = 10,
        dns_name = "zk"
    }
    "broker" = {
        count = 3,
        size = "Standard_A2m_v2",
        volume_size = 50,
        dns_name = "kafka"
    }
    "connect" = {
        count = 0,
        size = "SStandard_A2m_v2",
        volume_size = 40,
        dns_name = "connect"
    }
    "schemaregistry" = {
        count = 0,
        size = "Standard_A2m_v2",
        volume_size = 30,
        dns_name = "schemaregistry"
    }
    "restproxy" = {
        count = 0,
        size = "Standard_A2m_v2",
        volume_size = 10,
        dns_name = "restproxy"
    }
    "controlcenter" = {
        count = 0,
        size = "Standard_A2m_v2",
        volume_size = 30,
        dns_name = "kafka"
    }
    "ksql" = {
        count = 0,
        size = "Standard_A2m_v2",
        volume_size = 30,
        dns_name = "ksql"
    }
  }
}
