module "vpc" {
  source = "github.com/terraform-ibm-modules/terraform-ibm-toolkit-vpc"

  resource_group_name = module.resource_group.name
  region              = var.region
  name_prefix         = local.name_prefix
  common_tags = local.common_tags
  tags = ["vpc"]
}

module "subnets" {
  source = "github.com/terraform-ibm-modules/terraform-ibm-toolkit-vpc-subnets"

  resource_group_name = module.resource_group.name
  region            = var.region
  vpc_name          = module.vpc.name
  gateways          = module.gateways.gateways
  _count            = 2
  label             = "cluster"
  common_tags = local.common_tags
  tags = ["subnet"]
}

module "gateways" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc-gateways.git"

  resource_group_id = module.resource_group.id
  region            = var.region
  vpc_name          = module.vpc.name
  common_tags = local.common_tags
  tags = ["gateway"]
}

module "cos" {
  source = "github.com/terraform-ibm-modules/terraform-ibm-toolkit-object-storage"

  provision = true
  resource_group_name = module.resource_group.name
  name_prefix = local.name_prefix
  common_tags = local.common_tags
  tags = ["cos"]
}

module "dev_cluster" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-ocp-vpc.git"

  resource_group_name = module.resource_group.name
  region              = var.region
  ibmcloud_api_key    = var.ibmcloud_api_key
  name                = var.cluster_name
  worker_count        = var.worker_count
  ocp_version         = var.ocp_version
  exists              = false
  name_prefix         = local.name_prefix
  vpc_name            = module.subnets.vpc_name
  vpc_subnets         = module.subnets.subnets
  vpc_subnet_count    = module.subnets.count
  cos_id              = module.cos.id
  common_tags         = local.common_tags
  tags = ["openshift"]
}

resource null_resource write_kubeconfig {
  provisioner "local-exec" {
    command = "echo '${module.dev_cluster.platform.kubeconfig}' > ${path.cwd}/kubeconfig"
  }
}
