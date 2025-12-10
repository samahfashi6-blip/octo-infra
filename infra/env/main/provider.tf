terraform {
  backend "gcs" {
    bucket = "octo-education-tf-state"
    prefix = "env/main"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
