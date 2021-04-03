variable "environment_name" {
  type = string
}

### Common GCP variables ###

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "network" {
  type = string
}

### Common GKE variables ###

variable "name" {
  type = string
}

variable "subnet_nodes" {
  type = string
}

variable "subnet_pods" {
  type = string
}

variable "subnet_services" {
  type = string
}

variable "max_pods_per_node" {
  type = number
}

variable "cluster_git_url" {
  type = string
}

variable "cluster_git_path" {
  type = string
}
