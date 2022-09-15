module "dev_tools_mymodule" {
  source = "./module"

  resource_group_name = module.resource_group.name
  region              = var.region
  config_file_path    = module.dev_cluster.config_file_path
  ibmcloud_api_key    = var.ibmcloud_api_key
  cluster_namespace   = module.dev_tools_namespace.name
  registry_namespace   = dev_tools_namespace.namespace.name
}
