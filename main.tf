# Hauptkonfiguration
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.5.0"
    }
  }
}

# Google Cloud Provider Konfiguration
provider "google" {
  credentials = file("./gcpkey.json")
  project     = "systemdesign-387616"
  region      = "us-central1"
}
resource "google_compute_firewall" "firewall" {
  name    = "gritfy-firewall-externalssh"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"] # Not So Secure. Limit the Source Range
  target_tags   = ["externalssh"]
}
resource "google_compute_firewall" "webserverrule" {
  name    = "gritfy-webserver"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80","443"]
  }
  source_ranges = ["0.0.0.0/0"] # Not So Secure. Limit the Source Range
  target_tags   = ["webserver"]
}

# Ressourcen erstellen
resource "google_compute_instance" "web" {
  name         = "web"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"
  tags         = ["externalssh","webserver"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }

  metadata = {
    ssh-keys = file("./ssh.pub")
  }

provisioner "remote-exec" { 
  connection { 
      type = "ssh" 
      user = "sandr"
      private_key = file("./ssh")
      host = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
  } 
  inline = [ 
    "sudo apt update",
    "sudo apt install -y python3" 
    ] 
  }
    depends_on = [ google_compute_firewall.firewall, google_compute_firewall.webserverrule ]
}

resource "google_compute_instance" "app" {
  name         = "app"
  machine_type = "n1-standard-2"
  zone         = "us-central1-a"
  tags         = ["externalssh","webserver"]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }
  
  network_interface {
    network = "default"
    access_config {
    }
  }

  metadata = {
    ssh-keys = file("./ssh.pub")
  }

provisioner "remote-exec" { 
  connection { 
      type = "ssh" 
      user = "sandr"
      private_key = file("./ssh")
      host = google_compute_instance.app.network_interface[0].access_config[0].nat_ip
  } 
  inline = [ 
    "sudo apt update",
    "sudo apt install -y python3" 
    ] 
  }
   depends_on = [ google_compute_firewall.firewall, google_compute_firewall.webserverrule ]
}

resource "google_compute_instance" "db" {
  name         = "db"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"
  tags         = ["externalssh","webserver"]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }
  
  network_interface {
    network = "default"
    access_config {
    }
  }

  metadata = {
    ssh-keys = file("./ssh.pub")
  }

provisioner "remote-exec" { 
  connection { 
      type = "ssh" 
      user = "sandr"
      private_key = file("./ssh")
      host = google_compute_instance.db.network_interface[0].access_config[0].nat_ip
  } 
  inline = [ 
    "sudo apt update",
    "sudo apt install -y python3" 
    ] 
  }
   depends_on = [ google_compute_firewall.firewall, google_compute_firewall.webserverrule ]
}