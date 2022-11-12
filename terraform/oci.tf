locals {
  tenancy_ocid        = data.sops_file.terraform.data["oci.tenancy_ocid"]
  root_compartment_id = local.tenancy_ocid
}

provider "oci" {
  tenancy_ocid = local.tenancy_ocid
  user_ocid    = data.sops_file.terraform.data["oci.user_ocid"]
  region       = data.sops_file.terraform.data["oci.region"]
  fingerprint  = data.sops_file.terraform.data["oci.fingerprint"]
  private_key  = data.sops_file.terraform.data["oci.private_key"]
}
resource "oci_identity_compartment" "terraform" {
  compartment_id = local.root_compartment_id
  name           = "terraform"
  description    = "Terraform-managed compartment"
}

locals {
  compartment_id = oci_identity_compartment.terraform.id
}

data "oci_identity_availability_domains" "main" {
  compartment_id = local.tenancy_ocid
  filter {
    name   = "name"
    values = [data.sops_file.terraform.data["oci.availability_domain_name"]]
  }
}

locals {
  availability_domain = data.oci_identity_availability_domains.main.availability_domains[0]
}

data "oci_objectstorage_namespace" "main" {
  compartment_id = local.compartment_id
}

resource "oci_objectstorage_bucket" "images" {
  compartment_id = local.compartment_id
  name           = "images"
  namespace      = data.oci_objectstorage_namespace.main.namespace
  access_type    = "NoPublicAccess"
}

locals {
  main_cidr_block = "10.0.0.0/16"
}

resource "oci_core_vcn" "main" {
  compartment_id = local.compartment_id
  display_name   = "main"
  dns_label      = "main"
  is_ipv6enabled = true
  cidr_blocks = [
    local.main_cidr_block
  ]
}

resource "oci_core_default_dhcp_options" "main" {
  manage_default_resource_id = oci_core_vcn.main.default_dhcp_options_id
  display_name               = "main"
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
  options {
    type                = "SearchDomain"
    search_domain_names = ["${oci_core_vcn.main.dns_label}.oraclevcn.com"]
  }
}

resource "oci_core_subnet" "public" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "main-public"
  dns_label      = "public"
  cidr_block     = cidrsubnet(oci_core_vcn.main.cidr_blocks[0], 8, 0)
  ipv6cidr_block = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, 0)
  security_list_ids = [
    oci_core_default_security_list.public.id
  ]
}

resource "oci_core_subnet" "private" {
  compartment_id             = local.compartment_id
  vcn_id                     = oci_core_vcn.main.id
  display_name               = "main-private"
  dns_label                  = "private"
  cidr_block                 = cidrsubnet(oci_core_vcn.main.cidr_blocks[0], 8, 1)
  ipv6cidr_block             = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, 1)
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
  security_list_ids = [
    oci_core_security_list.private.id
  ]
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "main-internet-gateway"
}

resource "oci_core_nat_gateway" "main" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "main-nat-gateway"
}

resource "oci_core_service_gateway" "main" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "main-service-gateway"
  services {
    service_id = local.all-iad-service.id
  }
}

resource "oci_core_default_route_table" "public" {
  manage_default_resource_id = oci_core_vcn.main.default_route_table_id
  display_name               = "test"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "private"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.main.id
  }
  route_rules {
    destination       = local.all-iad-service.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.main.id
  }
}

locals {
  all-iad-service = data.oci_core_services.all-iad.services[0]
}

data "oci_core_services" "all-iad" {
  filter {
    name   = "name"
    values = ["All IAD Services In Oracle Services Network"]
  }
}

locals {
  protocol_icmp      = 1
  protocol_tcp       = 6
  protocol_ipv6_icmp = 58
}

resource "oci_core_default_security_list" "public" {
  manage_default_resource_id = oci_core_vcn.main.default_security_list_id
  display_name               = "public"

  ingress_security_rules {
    protocol = local.protocol_tcp
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    protocol = local.protocol_tcp
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    protocol = local.protocol_tcp
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }
  ingress_security_rules {
    protocol = local.protocol_icmp
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = local.protocol_ipv6_icmp
    source   = "::/0"
  }
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_security_list" "private" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "private"

  ingress_security_rules {
    protocol = local.protocol_tcp
    source   = local.main_cidr_block
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    protocol = local.protocol_tcp
    source   = local.main_cidr_block
    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    protocol = local.protocol_tcp
    source   = local.main_cidr_block
    tcp_options {
      min = 443
      max = 443
    }
  }
  ingress_security_rules {
    protocol = local.protocol_icmp
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = local.protocol_ipv6_icmp
    source   = "::/0"
  }
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

data "oci_core_images" "ubuntu" {
  compartment_id = local.compartment_id
  display_name   = "Canonical-Ubuntu-22.04-aarch64-2022.08.10-0"
}

locals {
  ubuntu_image = data.oci_core_images.ubuntu.images[0]
}

resource "oci_core_instance" "a1" {
  compartment_id      = local.compartment_id
  availability_domain = local.availability_domain.name
  display_name        = "a1"
  # always free shapes
  # VM.Standard.E2.1.Micro - up to 2 instances
  # VM.Standard.A1.Flex - up to 4 ocpu, 24GB mem
  shape = "VM.Standard.A1.Flex"
  create_vnic_details {
    subnet_id      = oci_core_subnet.public.id
    hostname_label = "a1"
  }
  source_details {
    # install ubuntu 22.04 first
    # then install nixos using kexec
    source_id               = local.ubuntu_image.id
    source_type             = "image"
    boot_volume_size_in_gbs = 150 # 200GB always free
  }
  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }
  metadata = {
    ssh_authorized_keys = file("${path.module}/../users/root/ssh/pgp.pub")
  }
}
