# Add Default backend to throw 404 errors
# if hostname doesn't match anything that we need.

# Add default backend config ####################

locals {
  default_env = { default = "example.com" }
}

# Merge with user-supplied config ###############

locals {
  all_env = merge(
    var.bucket_deployments,
    local.default_env
  )
  not_found = "404.html"
}

# Add default settings for backend services ########

# We use /hc path and port 8080 here 
# as the default one for Kubernetes services

# We use empty groups array
# to populate the backends from Kubernetes dynamically
# by Google AutoNEG feature
# https://github.com/GoogleCloudPlatform/gke-autoneg-controller

# disabled log_config entries are constantly reset upon terraform apply
# terraform-provider-google issue
# https://github.com/hashicorp/terraform-provider-google/issues/6260

locals {
  health_check = {
    check_interval_sec  = null
    timeout_sec         = null
    healthy_threshold   = null
    unhealthy_threshold = null
    request_path        = var.health_check_path
    port                = var.health_check_port
    host                = null
    logging             = false
  }
}

locals {
  backend_service = {
    description                     = "Backend service for AutoNEG"
    protocol                        = var.health_check_protocol
    port                            = var.health_check_port
    port_name                       = var.health_check_port_name
    timeout_sec                     = 10
    connection_draining_timeout_sec = null
    enable_cdn                      = false
    session_affinity                = "NONE"
    affinity_cookie_ttl_sec         = 0
    custom_request_headers          = []
    security_policy                 = null
    health_check                    = local.health_check
    iap_config = {
      enable               = false
      oauth2_client_id     = null
      oauth2_client_secret = null
    }
    log_config = {
      enable      = false
      sample_rate = null
    }
    groups = []
  }
}

# Create Google-managed SSL certificate #######

# Google-managed SSL certificate domain list cannot be updated in-place due to GCP restrictions,
# so it is necessary to use "create_before_destroy" lifecycle rule and generate unique resource names based on domains list
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_managed_ssl_certificate#example-usage---managed-ssl-certificate-recreation

locals {
  managed_domains = values(merge(var.bucket_deployments, var.k8s_services))
}

resource "random_id" "certificate" {
  byte_length = 4
  prefix      = "${lower(var.environment_name)}-google-managed-certificates-"

  keepers = {
    domains = join(",", local.managed_domains)
  }
}

resource "google_compute_managed_ssl_certificate" "cdn_certificate" {
  provider = google-beta
  project  = var.project

  name = random_id.certificate.hex

  managed {
    domains = local.managed_domains
  }

  lifecycle {
    create_before_destroy = true
  }

}

# Create GCP load balancer ####################

# We use the dynamic_backends submodule
# for globally available Kubernetes services

module "global-loadbalancer" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/dynamic_backends"
  project = var.project
  name    = "${lower(var.environment_name)}${lower(var.identifier)}-global-loadbalancer"

  ssl                  = true
  use_ssl_certificates = true
  ssl_certificates     = [google_compute_managed_ssl_certificate.cdn_certificate.self_link]

  firewall_networks = compact([var.firewall_network])
  firewall_projects = [var.host_project]

  // Make sure when you create the cluster that you provide the `--tags` argument to add the appropriate `target_tags` referenced in the http module.
  target_tags = []

  // Use custom url map.
  url_map        = google_compute_url_map.url-map.self_link
  create_url_map = false

  backends = {
    for service in keys(var.k8s_services) : service => local.backend_service
  }
}

output "loadbalancer-ip" {
  value = module.global-loadbalancer.external_ip
}

resource "google_compute_url_map" "url-map" {
  // note that this is the name of the load balancer
  provider = google
  name     = "${lower(var.environment_name)}${lower(var.identifier)}-global-loadbalancer"

  default_service = google_compute_backend_bucket.static_backend["default"].self_link

  // dynamic host rules for static content deployments 
  dynamic "host_rule" {
    for_each = var.bucket_deployments
    iterator = env

    content {
      hosts        = [env.value]
      path_matcher = env.key
    }
  }

  // dynamic host rules for kubernetes services
  dynamic "host_rule" {
    for_each = var.k8s_services
    iterator = service

    content {
      hosts        = [service.value]
      path_matcher = service.key
    }
  }

  dynamic "path_matcher" {
    for_each = var.bucket_deployments
    iterator = env

    content {
      name            = env.key
      default_service = google_compute_backend_bucket.static_backend[env.key].self_link
    }
  }

  dynamic "path_matcher" {
    for_each = var.k8s_services
    iterator = service

    content {
      name            = service.key
      default_service = module.global-loadbalancer.backend_services[service.key].self_link
    }
  }
}

# Create backend buckets ###############

resource "google_compute_backend_bucket" "static_backend" {
  for_each    = local.all_env
  name        = "${lower(var.environment_name)}${lower(var.identifier)}-${each.key}-backend"
  description = each.key == "default" ? "Default 404 bucket" : "Static assets for (${lower(var.environment_name)} | ${each.key})"
  bucket_name = google_storage_bucket.static_backend_bucket[each.key].name
  enable_cdn  = each.key == "default" ? false : true
}
