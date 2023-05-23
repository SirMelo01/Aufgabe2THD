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
  credentials = file("<GCP_SERVICE_ACCOUNT_KEY_JSON_FILE>")
  project     = "<PROJECT_ID>"
  region      = "us-central1"
}

# Ressourcen erstellen
resource "google_compute_instance" "web" {
  name         = "web"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"
  
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
}

resource "google_compute_instance" "app" {
  name         = "app"
  machine_type = "n1-standard-2"
  zone         = "us-central1-a"
  
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
}

resource "google_compute_instance" "db" {
  name         = "db"
  machine_type = "db-n1-standard-1"
  zone         = "us-central1-a"
  
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
}