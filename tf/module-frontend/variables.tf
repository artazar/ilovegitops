variable "environment_name" {
  type        = string
  description = "Environment name"
}

variable "identifier" {
  type        = string
  description = "An additional identifier for multiple configurations within the same environment"
  default     = ""
}

### Common GCP variables ###

variable "project" {
  type        = string
  description = "The project ID to host the cluster in"
}

variable "region" {
  type        = string
  description = "The region to host the cluster in"
}

variable "host_project" {
  type        = string
  description = "The GCP project housing the VPC network to host the cluster in"
}

variable "firewall_network" {
  type        = string
  description = "The GCP network to apply firewall rules in. Set it only in case of Kubernetes backends."
  default     = null
}

### Google LB module variables ###

variable "health_check_path" {
  type        = string
  description = "Backend Health Check path"
  default     = "/"
}

variable "health_check_port" {
  type        = string
  description = "Backend Health Check port"
  default     = "80"
}

variable "health_check_port_name" {
  type        = string
  description = "Backend Health Check port name"
  default     = "http"
}

variable "health_check_protocol" {
  type        = string
  description = "Backend Health Check protocol"
  default     = "HTTP"
}

### Static assets hosting variables

variable "bucket_location" {
  type        = string
  description = "Bucket location (https://cloud.google.com/storage/docs/locations)"
  default     = "EU"
}

variable "bucket_deployments" {
  type        = map
  description = "Map for deployments served from GCS buckets"
  default     = {}
}

### K8S services hosting variables

variable "k8s_services" {
  type        = map
  description = "Map for applications served from GKE clusters"
  default     = {}
}
