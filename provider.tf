provider "helm" {
  kubernetes {
    config_path = var.config_file_path
  }
}
