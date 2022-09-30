# Resource Group Variables
variable "resource_group_name" {
  type        = string
  description = "The name of the IBM Cloud resource group where the cluster will be created/can be found."
}

variable "registry_namespace" {
  type        = string
  description = "The namespace that will be created in the IBM Cloud image registry. If not provided the value will default to the resource group"
  default     = ""
}

variable "registry_user" {
  type        = string
  description = "The username to authenticate to the IBM Container Registry"
  default     = "iamapikey"
}

variable "registry_password" {
  type        = string
  description = "The password (API key) to authenticate to the IBM Container Registry. If not provided the value will default to `var.ibmcloud_api_key`"
  default     = ""
}

variable "region" {
  type        = string
  description = "The region for the image registry been installed."
}

variable "config_file_path" {
  type        = string
  description = "The path to the kube config"
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}

variable "cluster_namespace" {
  type        = string
  description = "The namespace in the cluster where the configuration should be created (e.g. tools)"
}

variable "gitops_dir" {
  type        = string
  description = "The directory where the gitops configuration should be stored"
  default     = ""
}

variable "cluster_type_code" {
  type        = string
  description = "The cluster_type of the cluster"
  default     = "ocp4"
}

variable "apply" {
  type        = bool
  description = "Flag indicating that the module should be applied"
  default     = true
}

variable "private_endpoint" {
  type        = string
  description = "Flag indicating that the registry url should be created with private endpoints"
  default     = "true"
}
