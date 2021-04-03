terraform {
  required_version = "~> 0.12"

  required_providers {
    google = {
      version = ">= 3.38.0"
    }
    google-beta = {
      version = ">= 3.38.0"
    }
  }
}
