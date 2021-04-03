module "dev_cluster" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-ocp-vpc.git"

  resource_group_name     = module.resource_group.name
  name                    = var.cluster_name
  region                  = var.region
  ocp_version             = "4.6"
  exists                  = true
  ibmcloud_api_key        = var.ibmcloud_api_key
  name_prefix             = var.name_prefix
  vpc_name                = ""
  vpc_subnet_count        = 1
  cos_id                  = ""
}
