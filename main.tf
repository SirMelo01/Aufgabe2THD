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
# VPC Firewall Regeln für externen SSH Zugrif über tcp:22
resource "google_compute_firewall" "firewall" {
  name    = "gritfy-firewall-externalssh"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["externalssh"]
}
# Webserver Regel erstellen für tcp:80, tcp:443
resource "google_compute_firewall" "webserverrule" {
  name    = "gritfy-webserver"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80","443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webserver"]
}
# Mysql Firewall Regel erstellen für tcp:3306
resource "google_compute_firewall" "mysql" {
  name = "db-server"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["3306"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["dbserver"]
}

# Ressourcen Web erstellen für den Nginx Server
resource "google_compute_instance" "web" {
  name         = "web"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"
  tags         = ["externalssh","webserver"]
  # Initialisierung eines Debian Systems
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
# Provisioner für remote Befehlsausführung auf dem Server
provisioner "remote-exec" { 
  connection { 
      type = "ssh" 
      user = "sandro"
      private_key = file("./ssh")
      host = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
  } 
  inline = [ 
    "sudo apt update",
    "sudo apt install -y python3" 
    ] 
  }
  # Provisioner für Loakle Ausführung des Ansible Playbooks, welches Nginx installiert und konfiguriert
  provisioner "local-exec" {
    command = "ansible-playbook nginx.yaml"
  }
    depends_on = [ google_compute_firewall.firewall, google_compute_firewall.webserverrule ]
}
# App Instanz erstellen
resource "google_compute_instance" "app" {
  name         = "app"
  machine_type = "n1-standard-2"
  zone         = "us-central1-a"
  tags         = ["externalssh","webserver"]
   # Initialisierung eines Debian Systems
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
# Provisioner für remote Befehlsausführung auf dem Server
provisioner "remote-exec" { 
  connection { 
      type = "ssh" 
      user = "sandro"
      private_key = file("./ssh")
      host = google_compute_instance.app.network_interface[0].access_config[0].nat_ip
  } 
  inline = [ 
    "sudo apt update",
    "sudo apt install -y python3" 
    ] 
  }
  # Provisioner für Loakle Ausführung des Ansible Playbooks, welches die Umgebung für die Spring App erstellt,
  # auf dem Server deployed und mit Maven ausführt
    provisioner "local-exec" {
    command = "ansible-playbook app.yaml"
  }
   depends_on = [ google_compute_firewall.firewall, google_compute_firewall.webserverrule ]
}
 #Erstellung der Datenbank Intanz
resource "google_compute_instance" "db" {
  name         = "db"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"
  tags         = ["externalssh","webserver", "dbserver"]
  # Initialisierung eines Debian Systems
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
# Provisioner für remote Befehlsausführung auf dem Server
provisioner "remote-exec" { 
  connection { 
      type = "ssh" 
      user = "sandro"
      private_key = file("./ssh")
      host = google_compute_instance.db.network_interface[0].access_config[0].nat_ip
  } 
  inline = [ 
    "sudo apt update",
    "sudo apt install -y python3" 
    ] 
  }
  # Provisioner für Loakle Ausführung des Ansible Playbooks, welches die Datenbank MariaDb installiert und mit einem User und Passwort versieht.
    provisioner "local-exec" {
    command = "ansible-playbook db.yaml"
  }
   depends_on = [ google_compute_firewall.firewall, google_compute_firewall.webserverrule ]
}