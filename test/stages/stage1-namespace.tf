module "dev_tools_namespace" {
  source = "github.com/cloud-native-toolkit/terraform-k8s-namespace.git"

  cluster_config_file_path = module.dev_cluster.config_file_path
  name                     = var.namespace
}

resource "random_string" "suffix" {
  length           = 16
  special          = true
  override_special = "/@*$"
  # Only Alpha numeric - dont pass special $ 
}
