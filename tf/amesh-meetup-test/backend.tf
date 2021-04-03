module "utils" {
  source = "terraform-google-modules/utils/google"
}

module "backend" {
  for_each          = var.regions
  source            = "../module-backend"
  project           = var.project
  region            = each.key
  network           = var.network
  environment_name  = var.environment_name
  name              = format("%s-gke-%s", var.environment_name, module.utils.region_short_name_map[each.key])
  subnet_nodes      = format("%s-gke-%s-nodes", var.environment_name, module.utils.region_short_name_map[each.key])
  subnet_pods       = format("%s-gke-%s-pods", var.environment_name, module.utils.region_short_name_map[each.key])
  subnet_services   = format("%s-gke-%s-services", var.environment_name, module.utils.region_short_name_map[each.key])
  max_pods_per_node = 16
  cluster_git_url   = "https://github.com/artazar/ilovegitops"
}
