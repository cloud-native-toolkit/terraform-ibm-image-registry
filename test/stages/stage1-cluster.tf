module "dev_cluster" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-ocp-vpc.git"

  resource_group_name     = module.resource_group.name
  cluster_name            = var.cluster_name
  cluster_region          = var.region
  ocp_version             = "4.6"
  cluster_exists          = true
  ibmcloud_api_key        = var.ibmcloud_api_key
  name_prefix             = var.name_prefix
}
