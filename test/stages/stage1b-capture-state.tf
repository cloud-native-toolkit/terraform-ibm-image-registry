module "dev_capture_tools_state" {
  source = "github.com/ibm-garage-cloud/terraform-k8s-capture-state"

  cluster_type             = "ocp4"
  cluster_config_file_path = module.dev_cluster.config_file_path
  namespace                = module.dev_tools_namespace.name
  output_path              = "${path.cwd}/cluster-state/before"
}
