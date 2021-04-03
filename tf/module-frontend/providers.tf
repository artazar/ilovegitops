provider "google" {
  project     = var.project
  region      = var.region
}

# Use Beta provider for Google-managed certificates
provider "google-beta" {
  project     = var.project
  region      = var.region
}
