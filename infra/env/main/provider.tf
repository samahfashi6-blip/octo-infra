terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Backend configuration moved to backend.tf
  # Uncomment backend.tf when ready to use remote state
}

provider "google" {
  project = var.project_id
  region  = var.region
}
