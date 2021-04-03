module "gke" {
  source             = "terraform-google-modules/kubernetes-engine/google"
  name               = var.name
  kubernetes_version = "latest"

  project_id        = var.project
  regional          = true
  region            = var.region
  network           = var.network
  subnetwork        = var.subnet_nodes
  ip_range_pods     = var.subnet_pods
  ip_range_services = var.subnet_services

  default_max_pods_per_node  = var.max_pods_per_node
  http_load_balancing        = true
  horizontal_pod_autoscaling = true
  network_policy             = false
  remove_default_node_pool   = true
  create_service_account     = false
  identity_namespace         = null
  node_metadata              = "UNSPECIFIED"

  node_pools = [
    {
      name               = "node-pool"
      machine_type       = "n1-standard-2"
      min_count          = 1
      max_count          = 1
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = false
      preemptible        = true
      initial_node_count = 1
    },

  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all = {}
  }


  node_pools_taints = {
    all = []
  }

  node_pools_tags = {
    all = [var.environment_name, ]
  }

}

data "template_file" "kubeconfig" {
  template = file("${path.module}/config.tpl")

  vars = {
    cluster_ca_certificate = module.gke.ca_certificate
    endpoint               = module.gke.endpoint
    suffix                 = "${var.environment_name}_${var.region}"
  }
}

resource "local_file" "kubeconfig" {
  content  = data.template_file.kubeconfig.rendered
  filename = "${var.environment_name}-${var.region}.kubeconfig"
}

/*
DISCLAIMER: The part below is added only due to the inability of terraform to manage providers inside for_each loops for modules.
When time comes, this can be replaced with proper terraform resources to be added to clusters in tf-native way.
Reference: https://github.com/hashicorp/terraform/issues/24476
*/

/*

Google AutoNEG controller to Kubernetes cluster:
https://github.com/GoogleCloudPlatform/gke-autoneg-controller

It is required to automatically populate the global load balancer with containers as backends.

*/

resource "null_resource" "autoneg" {
  provisioner "local-exec" {
    command = "kubectl --kubeconfig ${local_file.kubeconfig.filename} apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/gke-autoneg-controller/master/deploy/autoneg.yaml"
  }
}

/*
[Flux CD](https://fluxcd.io/) is installed in the deployed Kubernetes cluster(s) to manage all resources inside of it.
*/

resource "null_resource" "flux" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl --kubeconfig ${local_file.kubeconfig.filename} create namespace flux
      helm repo add fluxcd https://charts.fluxcd.io
      helm --kubeconfig ${local_file.kubeconfig.filename} upgrade --install flux fluxcd/flux --namespace flux --set git.url="${var.cluster_git_url}" --set git.branch="main" --set git.readonly=true --set syncGarbageCollection.enabled=true --set registry.disableScanning=true
      helm --kubeconfig ${local_file.kubeconfig.filename} upgrade --install helm-operator fluxcd/helm-operator --namespace flux --set helm.versions=v3 
    EOT
  }
}
