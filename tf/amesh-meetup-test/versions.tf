
terraform {

  required_version = ">= 0.12.29"

  required_providers {

    google = {
      version = ">= 3.38.0"
    }

    # We need the beta provider in order to use these parameters for GKE cluster:
    # - dns_cache
    # - enable_pod_security_policy
    # - node_pool_taints

    google-beta = {
      version = ">= 3.38.0"
    }

    kubernetes = {
      version = "1.13.3"
    }

    helm = {
      version = "1.3.0"
    }

    null = {
      version = "2.1.2"
    }

    template = {
      version = "2.1.2"
    }

    local = {
      version = "1.4.0"
    }

    external = {
      version = "1.2"
    }

    random = {
      version = "2.3"
    }

  }

}
