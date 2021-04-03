variable "environment_name" {
  type        = string
  description = "Environment name"
}

variable "project" {
  type        = string
  description = "The project ID to host the cluster in"
}

variable "network" {
  type        = string
  description = "The GCP network to apply firewall rules in"
}

variable "regions" {
  type        = set(string)
  description = "The region to host the cluster in"
}
