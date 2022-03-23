terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "4.68.0"
    }
  }
}

provider "oci" {
  auth                = "SecurityToken"
  config_file_profile = "Default"
  region              = var.region
}

# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.compartment_ocid
}

resource "oci_core_vcn" "vcn" {
  cidr_blocks    = var.vcn_cidr
  compartment_id = var.compartment_ocid
  display_name   = "BN-VCN"
}

resource "oci_core_security_list" "bn_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "BNSecurityList"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  // allow inbound ssh traffic from a specific port
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {

      // These values correspond to the destination port range.
      min = 22
      max = 22
    }
  }

  // allow inbound TCP
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 443
      max = 443
    }
  }


  // allow inbound icmp traffic of a specific type
  ingress_security_rules {
    protocol  = 1
    source    = "0.0.0.0/0"
    stateless = true

    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_core_subnet" "mgmt-subnet" {
  cidr_block        = var.mgmt_subnet
  display_name      = "MgmtSubnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.vcn.id
  security_list_ids = [oci_core_security_list.bn_security_list.id]
  route_table_id    = oci_core_route_table.bn_route_table.id
}

resource "oci_core_subnet" "public-subnet" {
  cidr_block        = var.public_subnet
  display_name      = "PublicSubnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.vcn.id
  security_list_ids = [oci_core_security_list.bn_security_list.id]
  route_table_id    = oci_core_route_table.bn_route_table.id
}

resource "oci_core_subnet" "private-subnet" {
  cidr_block        = var.private_subnet
  display_name      = "PrivateSubnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.vcn.id
  security_list_ids = [oci_core_security_list.bn_security_list.id]
  route_table_id    = oci_core_route_table.bn_route_table.id
}

resource "oci_core_internet_gateway" "vcnInternetGateway" {
  compartment_id = var.compartment_ocid
  display_name   = "IGW"
  vcn_id         = oci_core_vcn.vcn.id
}

resource "oci_core_route_table" "bn_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "BNRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.vcnInternetGateway.id
  }
}

resource "oci_core_image" "bn_image" {
  compartment_id = var.compartment_ocid
  display_name   = "bn-image"
  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = var.os_disk_url
  }
}

resource "oci_core_volume" "bn_data_disk" {
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[0]["name"]
  compartment_id      = var.compartment_ocid
  size_in_gbs         = "100"
  display_name        = "BN-DataDisk"
}

resource "oci_core_instance" "BN" {
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[0]["name"]
  compartment_id      = var.compartment_ocid
  display_name        = "BorderNet"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id              = oci_core_subnet.mgmt-subnet.id
    skip_source_dest_check = true
  }
  shape_config {

    memory_in_gbs = "8"
    ocpus         = "4"
  }
  metadata = {
    user_data = "${base64encode(file("./userdata.sh"))}"
  }
  source_details {
    source_id   = oci_core_image.bn_image.id
    source_type = "image"
  }
}

resource "oci_core_volume_attachment" "test_volume_attachment" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.BN.id
  volume_id       = oci_core_volume.bn_data_disk.id
}

resource "oci_core_vnic_attachment" "public_interface" {
  instance_id  = oci_core_instance.BN.id
  display_name = "Public_Interface"

  create_vnic_details {
    subnet_id              = oci_core_subnet.public-subnet.id
    display_name           = "public"
    assign_public_ip       = false
    skip_source_dest_check = true
  }
}

resource "oci_core_vnic_attachment" "private_interface" {
  instance_id  = oci_core_instance.BN.id
  display_name = "Private_Interface"

  create_vnic_details {
    subnet_id              = oci_core_subnet.private-subnet.id
    display_name           = "private"
    assign_public_ip       = false
    skip_source_dest_check = true
  }
}


output "MGMT_url" {
  value = "https://${oci_core_instance.BN.public_ip}/"
}

output "Private_ip" {
  description = "Private IPs of created instances. "
  value       = oci_core_vnic_attachment.private_interface.create_vnic_details[0].private_ip
}

output "Public_ip" {
  description = "Public IPs of created instances. "
  value       = oci_core_vnic_attachment.public_interface.create_vnic_details[0].private_ip
}


