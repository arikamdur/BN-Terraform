terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.1.0"
    }
  }
}

provider "google" {
  credentials = "account.json" ## create service account from GCP Console and download JSON key
  project     = "bordernet"
  region      = var.region1
  alias       = "region1"
}

provider "google" {
  credentials = "account.json" ## create service account from GCP Console and download JSON key
  project     = "bordernet"
  region      = var.region2
  alias       = "region2"
}

data "google_compute_zones" "region1_zone_available" {
  provider = google.region1
}

data "google_compute_zones" "region2_zone_available" {
  provider = google.region2
}


# # Create a Virtual Network
resource "google_compute_network" "mgmt_network_region1" {
  provider                = google.region1
  name                    = "bn-mgmt-network-region1"
  auto_create_subnetworks = "false"
}

resource "google_compute_network" "mgmt_network_region2" {
  provider                = google.region2
  name                    = "bn-mgmt-network-region2"
  auto_create_subnetworks = "false"
}

resource "google_compute_network" "public_network_region1" {
  provider                = google.region1
  name                    = "bn-public-network-region1"
  auto_create_subnetworks = "false"
}

resource "google_compute_network" "public_network_region2" {
  provider                = google.region2
  name                    = "bn-public-network-region2"
  auto_create_subnetworks = "false"
}


resource "google_compute_network" "private_network_region1" {
  provider                = google.region1
  name                    = "bn-private-network-region1"
  auto_create_subnetworks = "false"
}

resource "google_compute_network" "private_network_region2" {
  provider                = google.region2
  name                    = "bn-private-network-region2"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "mgmt_region1" {
  provider      = google.region1
  name          = "bn-mgmt-region1"
  ip_cidr_range = var.region1_mgmt_prefix
  region        = var.region1
  network       = google_compute_network.mgmt_network_region1.id
}

resource "google_compute_subnetwork" "mgmt_region2" {
  provider      = google.region2
  name          = "bn-mgmt-region2"
  ip_cidr_range = var.region2_mgmt_prefix
  region        = var.region2
  network       = google_compute_network.mgmt_network_region2.id
}

resource "google_compute_subnetwork" "public_region1" {
  provider      = google.region1
  name          = "bn-public-region1"
  ip_cidr_range = var.region1_public_prefix
  region        = var.region1
  network       = google_compute_network.public_network_region1.id
}

resource "google_compute_subnetwork" "public_region2" {
  provider      = google.region2
  name          = "bn-public-region2"
  ip_cidr_range = var.region2_public_prefix
  region        = var.region2
  network       = google_compute_network.public_network_region2.id
}

resource "google_compute_subnetwork" "private_region1" {
  provider      = google.region1
  name          = "bn-private-region1"
  ip_cidr_range = var.region1_private_prefix
  region        = var.region1
  network       = google_compute_network.private_network_region1.id
}

resource "google_compute_subnetwork" "private_region2" {
  provider      = google.region2
  name          = "bn-private-region2"
  ip_cidr_range = var.region2_private_prefix
  region        = var.region2
  network       = google_compute_network.private_network_region2.id
}

resource "google_compute_firewall" "external_mgmt_default_region1" {
  provider = google.region1
  name     = "external-mgmt-firewall-region1"
  network  = google_compute_network.mgmt_network_region1.id


  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "internal_mgmt_default_region1" {
  provider = google.region1
  name     = "internal-mgmt-firewall-region1"
  network  = google_compute_network.mgmt_network_region1.id

  allow {
    protocol = "all"
  }

  source_ranges = [var.region2_mgmt_prefix]

}

resource "google_compute_firewall" "external_mgmt_default_region2" {
  provider = google.region2
  name     = "external-mgmt-firewall-region2"
  network  = google_compute_network.mgmt_network_region2.id


  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }
  source_ranges = ["0.0.0.0/0"]

}

resource "google_compute_firewall" "internal_mgmt_default_region2" {
  provider = google.region2
  name     = "internal-mgmt-firewall-region2"
  network  = google_compute_network.mgmt_network_region2.id

  allow {
    protocol = "all"
  }

  source_ranges = [var.region1_mgmt_prefix]

}

resource "google_compute_firewall" "public_default_region1" {
  provider = google.region1
  name     = "public-firewall-region1"
  network  = google_compute_network.public_network_region1.id

  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]

}

resource "google_compute_firewall" "public_default_region2" {
  provider = google.region2
  name     = "public-firewall-region2"
  network  = google_compute_network.public_network_region2.id

  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]

}

resource "google_compute_firewall" "private_default_region1" {
  provider = google.region1
  name     = "private-firewall-region1"
  network  = google_compute_network.private_network_region1.id

  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]

}

resource "google_compute_firewall" "private_default_region2" {
  provider = google.region2
  name     = "private-firewall-region2"
  network  = google_compute_network.private_network_region2.id

  allow {
    protocol = "all"

  }
  source_ranges = ["0.0.0.0/0"]

}

resource "google_compute_network_peering" "peering_region1" {
  provider     = google.region1
  name         = "region1-peering1"
  network      = google_compute_network.mgmt_network_region1.id
  peer_network = google_compute_network.mgmt_network_region2.id
}

resource "google_compute_network_peering" "peering_region2" {
  provider     = google.region2
  name         = "region2-peering2"
  network      = google_compute_network.mgmt_network_region2.id
  peer_network = google_compute_network.mgmt_network_region1.id
  depends_on   = [google_compute_network_peering.peering_region1, google_compute_network.mgmt_network_region2]
}


resource "google_compute_address" "bn-pip-region1" {
  provider = google.region1
  name     = "bn-pip-region1"
}

resource "google_compute_address" "bn-pip-region2" {
  provider = google.region2
  name     = "bn-pip-region2"
}

resource "google_compute_address" "sipp-pip" {
  provider = google.region1
  name     = "sipp-pip"
}


resource "google_compute_image" "bn_os_image_region1" {
  provider = google.region1
  name     = "bn-os-image-region1"

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

resource "google_compute_image" "bn_os_image_region2" {
  provider = google.region2
  name     = "bn-os-image-region2"

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

resource "google_compute_image" "bn_data_image_region1" {
  provider = google.region1
  name     = "bn-data-image-region1"
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

resource "google_compute_image" "bn_data_image_region2" {
  provider = google.region2
  name     = "bn-data-image-region2"
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

resource "google_compute_disk" "bn_os_disk_region1" {
  provider                  = google.region1
  name                      = "bn-os-disk"
  type                      = "pd-ssd"
  zone                      = data.google_compute_zones.region1_zone_available.names[0]
  image                     = google_compute_image.bn_os_image_region1.id
  physical_block_size_bytes = 4096
}

resource "google_compute_disk" "bn_os_disk_region2" {
  provider                  = google.region2
  name                      = "bn-os-disk"
  type                      = "pd-ssd"
  zone                      = data.google_compute_zones.region2_zone_available.names[0]
  image                     = google_compute_image.bn_os_image_region2.id
  physical_block_size_bytes = 4096
}



resource "google_compute_disk" "bn_data_disk_region1" {
  provider                  = google.region1
  name                      = "bn-data-disk"
  type                      = "pd-ssd"
  zone                      = data.google_compute_zones.region1_zone_available.names[0]
  image                     = google_compute_image.bn_data_image_region1.id
  physical_block_size_bytes = 4096
}

resource "google_compute_disk" "bn_data_disk_region2" {
  provider                  = google.region2
  name                      = "bn-data-disk"
  type                      = "pd-ssd"
  zone                      = data.google_compute_zones.region2_zone_available.names[0]
  image                     = google_compute_image.bn_data_image_region2.id
  physical_block_size_bytes = 4096
}

resource "google_compute_instance" "bn1" {
  provider     = google.region1
  name         = "bn1"
  machine_type = var.vm_size
  zone         = data.google_compute_zones.region1_zone_available.names[0]

  boot_disk {
    source = google_compute_disk.bn_os_disk_region1.id
  }
  attached_disk {
    source = google_compute_disk.bn_data_disk_region1.id
  }
  network_interface {
    subnetwork = google_compute_subnetwork.mgmt_region1.id
    access_config {
      nat_ip = google_compute_address.bn-pip-region1.address
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_region1.id
  }
  network_interface {
    subnetwork = google_compute_subnetwork.private_region1.id
  }
}

resource "google_compute_instance" "bn2" {
  provider     = google.region2
  name         = "bn2"
  machine_type = var.vm_size
  zone         = data.google_compute_zones.region2_zone_available.names[0]

  boot_disk {
    source = google_compute_disk.bn_os_disk_region2.id
  }
  attached_disk {
    source = google_compute_disk.bn_data_disk_region2.id
  }
  network_interface {
    subnetwork = google_compute_subnetwork.mgmt_region2.id
    access_config {
      nat_ip = google_compute_address.bn-pip-region2.address
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_region2.id
  }
  network_interface {
    subnetwork = google_compute_subnetwork.private_region2.id
  }
}



resource "google_compute_instance" "sipp" {
  provider     = google.region1
  name         = "sipp"
  machine_type = "t2d-standard-1"
  zone         = data.google_compute_zones.region1_zone_available.names[0]


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
    subnetwork = google_compute_subnetwork.public_region1.id
    access_config {
      nat_ip = google_compute_address.sipp-pip.address
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.private_region1.id
  }

}

output "MGMT_BN1_url" {
  value = "https://${google_compute_address.bn-pip-region1.address}/"
}

output "MGMT_BN2_url" {
  value = "https://${google_compute_address.bn-pip-region2.address}/"
}

output "BN1_Private" {
  value = google_compute_instance.bn1.network_interface.0.network_ip
}

output "BN2_Private" {
  value = google_compute_instance.bn2.network_interface.0.network_ip
}

output "SIPP" {
  value       = google_compute_address.sipp-pip.address
  description = "Login with ubuntu/sipp123"
}