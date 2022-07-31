terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.30.0"
    }
  }
}

provider "google" {
  credentials     = "account.json" ## create service account from GCP Console and download JSON key
  project         = "bordernet"
  region          = var.region
  request_timeout = "10m"
}

data "google_compute_zones" "available_zones" {}

# # Create a Virtual Network
resource "google_compute_network" "mgmt_network" {
  name                    = "bn-mgmt-network"
  auto_create_subnetworks = "false"

}

resource "google_compute_network" "public_network" {
  name                    = "bn-public-network"
  auto_create_subnetworks = "false"

}

resource "google_compute_network" "private_network" {
  name                    = "bn-private-network"
  auto_create_subnetworks = "false"

}

resource "google_compute_subnetwork" "mgmt" {
  name          = "bn-mgmt"
  ip_cidr_range = var.mgmt_prefix
  region        = var.region
  network       = google_compute_network.mgmt_network.id
}

resource "google_compute_subnetwork" "public" {
  name          = "bn-public"
  ip_cidr_range = var.public_prefix
  region        = var.region
  network       = google_compute_network.public_network.id
}

resource "google_compute_subnetwork" "private" {
  name          = "bn-private"
  ip_cidr_range = var.private_prefix
  region        = var.region
  network       = google_compute_network.private_network.id
}

resource "google_compute_firewall" "mgmt_default" {
  name    = "mgmt-firewall"
  network = google_compute_network.mgmt_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }
  source_ranges = ["0.0.0.0/0"]


}

resource "google_compute_firewall" "public_default" {
  name    = "public-firewall"
  network = google_compute_network.public_network.id

  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]

}

resource "google_compute_firewall" "private_default" {
  name    = "private-firewall"
  network = google_compute_network.private_network.id

  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]

}


resource "google_compute_address" "bn-pip" {
  for_each = toset(var.bn_vm_names)
  name     = "${each.key}-pip"
}

resource "google_compute_address" "sipp-pip" {
  for_each = toset(var.sipp_vm_names)
  name     = "${each.key}-pip"
}


resource "google_compute_image" "bn_os_image" {
  name = "bn-os-image"

  raw_disk {
    source = var.os_disk
  }
  guest_os_features {
    type = "MULTI_IP_SUBNET"
  }
  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }
}

resource "google_compute_image" "bn_data_image" {
  name = "bn-data-image"
  timeouts {
    create = "10m"
  }

  raw_disk {
    source = var.data_disk
  }
  guest_os_features {
    type = "MULTI_IP_SUBNET"
  }
}

resource "google_compute_disk" "bn_os_disk" {
  for_each                  = toset(var.bn_vm_names)
  name                      = "bn-osdisk-${each.key}"
  type                      = "pd-ssd"
  zone                      = data.google_compute_zones.available_zones.names[0]
  image                     = google_compute_image.bn_os_image.id
  physical_block_size_bytes = 4096
}

resource "google_compute_disk" "bn_data_disk" {
  for_each                  = toset(var.bn_vm_names)
  name                      = "bn-datadisk-${each.key}"
  type                      = "pd-ssd"
  zone                      = data.google_compute_zones.available_zones.names[0]
  image                     = google_compute_image.bn_data_image.id
  physical_block_size_bytes = 4096
}

resource "google_compute_instance" "bn1" {
  for_each     = toset(var.bn_vm_names)
  name         = each.key
  machine_type = var.bn_vm_size
  zone         = data.google_compute_zones.available_zones.names[0]

  boot_disk {
    source = google_compute_disk.bn_os_disk[each.key].id
  }
  attached_disk {
    source = google_compute_disk.bn_data_disk[each.key].id
  }
  network_interface {
    subnetwork = google_compute_subnetwork.mgmt.id
    access_config {
      nat_ip = google_compute_address.bn-pip[each.key].address
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public.id
  }
  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }
}

resource "google_compute_instance" "sipp" {
  for_each     = toset(var.sipp_vm_names)
  name         = each.key
  machine_type = "t2d-standard-1"
  zone         = data.google_compute_zones.available_zones.names[0]


  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      type  = "pd-ssd"
      size  = 20
    }
  }


  metadata_startup_script = <<SCRIPT
  #!/bin/bash
  sudo su
  apt-get update
  apt-get install -y pkg-config dh-autoreconf ncurses-dev build-essential libssl-dev libpcap-dev libncurses5-dev libsctp-dev cmake
  sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
  sudo service sshd restart
  echo "ubuntu:sipp123" | chpasswd
  cd /root
  wget https://github.com/SIPp/sipp/releases/download/v3.6.1/sipp-3.6.1.tar.gz
  tar -xzvf sipp-3.6.1.tar.gz
  cd sipp-3.6.1
  ./build.sh --common
  SCRIPT

  scheduling {
    preemptible         = true
    automatic_restart   = false
    on_host_maintenance = false
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    access_config {
      nat_ip = google_compute_address.sipp-pip[each.key].address
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

}


output "BN_IPs" {
  value = { for k, v in google_compute_address.bn-pip : k => v.address }
}

output "SIPP_IPs" {
  value       = { for k, v in google_compute_address.sipp-pip : k => v.address }
  description = "Login with ubuntu/sipp123"
}

output "BN_Public_IPs" {
  value = { for k, v in google_compute_instance.bn1 : k => v.network_interface.1.network_ip }
}

output "BN_Private_IPs" {
  value = { for k, v in google_compute_instance.bn1 : k => v.network_interface.2.network_ip }
}