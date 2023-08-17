# GCP config
variable "gcp_credentials_file" {}
variable "gcp_project_id"       {}
variable "gcp_region"           { default = "us-west1" }
variable "gcp_storage_region"   { default = "us"}

variable "gcp_project_services" {
  type    = list
  default = [
    # NAME                                    TITLE
    "compute.googleapis.com",              # Google Compute Engine API
    "iam.googleapis.com",                  # Google Identity and Access Management (IAM) API
    "serviceusage.googleapis.com",         # Google Service Usage API
    "storage-component.googleapis.com",    # Google Cloud Storage
    "cloudapis.googleapis.com",            # Google Cloud APIs
    "servicemanagement.googleapis.com",    # Google Service Management API
    "storage-api.googleapis.com",          # Google Cloud Storage JSON API
    "cloudresourcemanager.googleapis.com", # Google Cloud Resource Manager API
    "deploymentmanager.googleapis.com",    # Google Cloud Deployment Manager V2 API
  ]
}

# Network variables

variable "subnet_cidr" {
  type    = map
  default = {
    "public_subnet"  = "10.0.10.0/24"
    "k8s" = "10.0.11.0/24"
  }
}

#variable "default_kubernetes_cidrs" {
#   type   = map
#   default = {
#     "kubePodsCIDR" = "10.233.64.0/18"
#     "kubeServiceCIDR" = "10.233.0.0/18"
#   }
#}

variable "source_ext_cidr" {}


variable "instance_hostname" {
  type = map
  default = {
    "bastion"          = "bastion"
    "k8s"            = "k8s"
  }
}

# GCE details
variable "gce_machine_type" {
  type = map
  default = {
    "bastion"          = "n1-standard-1"
    "k8s"            = "n2-standard-4"
  }
}

variable "gce_image_name" {
  type = map
  default = {
    "bastion"          = "ubuntu-os-cloud/ubuntu-2204-lts"
    "k8s"            = "ubuntu-os-cloud/ubuntu-2204-lts"
  }
}

variable "k8s_disk" {
  type    = map
  default = {
    "type"          = "pd-standard"
    "size"          = "10"
  }
}

variable "os_disk_size" {
  type = map
  default = {
    "bastion"          = "20"
    "k8s"            = "30"
  }
}

variable "ip_addr" {
  type = map
  default = {
    "bastion"      = "10.0.10.2"
  }
}

variable "instance_count" { default = "3" }

variable "k8s_user"    { default = "k8s" }
variable "k8s_pubkey"  {}
variable "k8s_privkey" {}

variable "kubekey_version"   { default = "v3.0.10" }
variable "k8s_version"       { default = "v1.25.3" }
variable "kubesphere_version" { default = "v3.4.0" }

variable "deploy_spark" {
  description = "Boolean flag to control deployment of the Spark module."
  type        = bool
  default     = false
}
