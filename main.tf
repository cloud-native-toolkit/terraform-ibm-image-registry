
locals {
  tmp_dir               = "${path.cwd}/.tmp"
  bin_dir               = module.setup_clis.bin_dir
  gitops_dir            = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_name            = "image-registry"
  chart_dir             = "${local.gitops_dir}/${local.chart_name}"
  registry_url_file     = "${local.tmp_dir}/registry_url.val"
  registry_namespace    = var.registry_namespace != "" ? var.registry_namespace : var.resource_group_name
  registry_user         = var.registry_user != "" ? var.registry_user : "iamapikey"
  registry_password     = var.registry_password != "" ? var.registry_password : var.ibmcloud_api_key
  registry_url          = var.apply ? data.local_file.registry_url[0].content : ""
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

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  clis = ["helm"]
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

resource null_resource ibmcloud_login {
  count = var.apply ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/scripts/ibmcloud-login.sh ${var.region} ${var.resource_group_name}"

    environment = {
      APIKEY = var.ibmcloud_api_key
    }
  }
}

# this should probably be moved to a separate module that operates at a namespace level
resource "null_resource" "create_registry_namespace" {
  count = var.apply ? 1 : 0
  depends_on = [null_resource.create_dirs, null_resource.ibmcloud_login]

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-registry-namespace.sh ${local.registry_namespace} ${var.region}"

    environment = {
      KUBECONFIG = var.config_file_path
    }
  }
}

resource null_resource write_registry_url {
  count = var.apply ? 1 : 0
  depends_on = [null_resource.create_registry_namespace]

  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/write-registry-url.sh ${var.region} ${local.registry_url_file}"
  }
}

data "local_file" "registry_url" {
  count = var.apply ? 1 : 0
  depends_on = [null_resource.write_registry_url]

  filename = local.registry_url_file
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
    command = "${self.triggers.bin_dir}/helm template image-registry ${self.triggers.chart_dir} -n ${self.triggers.namespace} | kubectl apply -n ${self.triggers.namespace} -f -"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/helm template image-registry ${self.triggers.chart_dir} -n ${self.triggers.namespace} | kubectl delete -n ${self.triggers.namespace} -f -"

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
      TMP_DIR    = local.tmp_dir
      KUBECONFIG = var.config_file_path
    }
  }
}
