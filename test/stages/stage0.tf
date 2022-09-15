terraform {
}

locals {
  name_prefix = "${random_string.name-prefix.result}"
}

resource "random_string" "name-prefix" {
  length           = 2
  special          = false
  upper = false
  numeric = false
}