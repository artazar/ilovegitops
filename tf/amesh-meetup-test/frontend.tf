module "frontend" {
  source           = "../module-frontend"
  environment_name = var.environment_name
  project          = var.project
  region           = "europe-west1"
  host_project     = var.project
  firewall_network = var.network
  k8s_services = {
    "myfancyapp" = "myfancyapp.example.com"
  }
}
