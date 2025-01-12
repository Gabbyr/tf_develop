terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "null" {}

variable "config_dir" {
  default = "./kind-configs"
}

# Create Kind cluster configuration files
resource "local_file" "kind_config" {
  count    = var.cluster_count
  filename = "${var.config_dir}/kind-cluster-dev-${count.index + 1}.yaml"

  content = <<EOT
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
EOT
}

# Create Kind clusters
resource "null_resource" "kind_cluster" {
  count = var.cluster_count

  depends_on = [local_file.kind_config]

  provisioner "local-exec" {
    command = "kind create cluster --name kind-cluster-dev-${count.index + 1} --config ${local_file.kind_config[count.index].filename}"
  }
}

# Import clusters into Rancher
resource "null_resource" "rancher_import" {
  count = var.cluster_count

  depends_on = [null_resource.kind_cluster]

  provisioner "local-exec" {
    # Generate Rancher import command
    command = <<EOT
    kind get kubeconfig --name kind-cluster-${count.index + 1} > /tmp/kubeconfig-kind-cluster-dev-${count.index + 1}.yaml
    KUBECONFIG=/tmp/kubeconfig-kind-cluster-${count.index + 1}.yaml \
    kubectl apply -f ${var.rancher_server_url}/v3/import/${var.rancher_import_token}.yaml
    EOT
  }
}

# Output
output "kind_clusters" {
  value = [for i in range(var.cluster_count) : "kind-cluster-dev-${i + 1}"]
}
