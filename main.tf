
locals {
  tmp_dir               = "${path.cwd}/.tmp"
  bin_dir               = data.clis_check.clis.bin_dir
  gitops_dir            = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_name            = "image-registry"
  chart_dir             = "${local.gitops_dir}/${local.chart_name}"
  registry_url_file     = "${local.tmp_dir}/registry_url.val"
  registry_namespace    = var.registry_namespace != "" ? var.registry_namespace : var.resource_group_name
  registry_user         = var.registry_user != "" ? var.registry_user : "iamapikey"
  registry_password     = var.registry_password != "" ? var.registry_password : var.ibmcloud_api_key
  registry_url          = var.apply ? module.registry_namespace[0].registry_server : ""
  release_name          = "image-registry"
  global_config = {
    clusterType = var.cluster_type_code
  }
  imageregistry_config  = {
    name = "registry"
    displayName = "Image Registry"
    url = "https://cloud.ibm.com/kubernetes/registry/main/images"
    privateUrl = "${var.private_endpoint == "true" ? "private." : ""}${local.registry_url}"
    otherSecrets = {
      namespace = local.registry_namespace
    }
    username = "iamapikey"
    password = var.ibmcloud_api_key
    category = "container-registry"
    applicationMenu = false
    enableConsoleLink = true
  }
}

data clis_check clis {
  clis = ["helm", "oc", "kubectl"]
}

resource "null_resource" "create_dirs" {
  count = var.apply ? 1 : 0

  provisioner "local-exec" {
    command = "mkdir -p ${local.tmp_dir}"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${local.gitops_dir}"
  }
}

module "registry_namespace" {
  source = "github.com/terraform-ibm-modules/terraform-ibm-toolkit-container-registry.git?ref=v1.1.5"
  count = var.apply ? 1 : 0

  resource_group_name = var.resource_group_name
  region              = var.region
  ibmcloud_api_key    = var.ibmcloud_api_key
  registry_namespace  = var.registry_namespace
  registry_user       = var.registry_user
  registry_password   = var.registry_password
}

resource "null_resource" "setup-chart" {
  count = var.apply ? 1 : 0
  depends_on = [null_resource.create_dirs]

  provisioner "local-exec" {
    command = "mkdir -p ${local.chart_dir} && cp -R ${path.module}/chart/${local.chart_name}/* ${local.chart_dir}"
  }
}

resource "local_file" "image-registry-values" {
  count = var.apply ? 1 : 0
  depends_on = [null_resource.setup-chart]

  content  = yamlencode({
    global = local.global_config
    tool-config = local.imageregistry_config
  })
  filename = "${local.chart_dir}/values.yaml"
}

resource "null_resource" "print-values" {
  count = var.apply ? 1 : 0
  provisioner "local-exec" {
    command = "cat ${local_file.image-registry-values[0].filename}"
  }
}

resource null_resource registry_setup {
  count = var.apply ? 1 : 0
  depends_on = [local_file.image-registry-values]

  triggers = {
    bin_dir = local.bin_dir
    chart_dir = local.chart_dir
    namespace = var.cluster_namespace
    kubeconfig = var.config_file_path
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/helm template image-registry ${self.triggers.chart_dir} -n ${self.triggers.namespace} | ${self.triggers.bin_dir}/kubectl apply -n ${self.triggers.namespace} -f -"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/helm template image-registry ${self.triggers.chart_dir} -n ${self.triggers.namespace} | ${self.triggers.bin_dir}/kubectl delete -n ${self.triggers.namespace} -f -"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}

resource "null_resource" "set_global_pull_secret" {
  count = var.apply ? 1 : 0
  depends_on = [null_resource.create_dirs]

  provisioner "local-exec" {
    command = "${path.module}/scripts/global-pull-secret.sh ${var.cluster_type_code}"

    environment = {
      BIN_DIR    = local.bin_dir
      TMP_DIR    = local.tmp_dir
      KUBECONFIG = var.config_file_path
    }
  }
}
