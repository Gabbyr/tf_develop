variable "cluster_count" {
  description = "Number of Kind clusters to create"
  default     = 5
}

variable "rancher_server_url" {
  description = "The URL of your Rancher server"
}

variable "rancher_import_token" {
  description = "Rancher API token with cluster import permissions"
}