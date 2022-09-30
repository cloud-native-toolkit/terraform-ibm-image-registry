terraform {
  required_providers {
    clis = {
      source  = "cloud-native-toolkit/clis"
    }
    ibm = {
      source = "ibm-cloud/ibm"
    }
  }
}

data clis_check clis_test {
  clis = ["kubectl", "oc"]
}

resource local_file bin_dir {
  filename = "${path.cwd}/.bin_dir"

  content = data.clis_check.clis_test.bin_dir
}

resource random_string suffix {
  length = 16

  upper = false
  special = false
}

locals {
  name_prefix = "ee-${random_string.suffix.result}"
  resource_group_name = "ee-${random_string.suffix.result}"
  common_tags = ["image-registry",random_string.suffix.result]
}
