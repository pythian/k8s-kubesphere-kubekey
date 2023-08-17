# Kubernetes cluster deployed on GCP compute images using kubekey for Kubesphere and Kubernetes installation

## The purpose of this project is to:
- Deploy compute instances on GCP
- Out of those instances 1 will be our bastion, the only one with an external IP that we could/should connect directly using SSH
- The remaining instances will be master/workers of the k8s cluster

## The goals:
- As kubekey does the big lift of installing Kubesphere and Kubernetes, we have not decided to create ansible playbooks on our own. Instead the approach was to run some tasks on remote-exec to overcome the basic elements that need to be there for that to happen
- Another major goal is to have a code that can survive upgrades of kubekey/kubesphere/kubernetes versions so we can deploy newer versions as they become available
- Another major goal is that we can do it the full deployment with just a "terraform apply" instead of having to manually run commands from the bastion or other instances

# Requirements

* terraform binaries (current version where this code was tested is 1.5.4 and can be downloaded directly from hasicorp to install)
* ssh client and related tools
* DNS should work to resolve all addresses (this will happen by default on cloud providers)
* It is recommended to have base install OS with no additional packages

## Pre-steps

* Create the GCP project
* Create a bucket to use as the terraform state backend, and add it's name into the remotestate.tf file
* A Service Account with admin privileges over the project needs to be created, and a correspondent JSON credentials file exported for use and saved locally at a known path/location
* Export the GOOGLE_APPLICATION_CREDENTIALS variable which is needed
* Create your terraform.tfvars file (see more about this below)
* Load your ssh keys as an ssh-agent  (more on how to do this on the next section)
* If this is your first execution of terraform on the code directory you will also need "terraform init"
* Run "terraform plan", if this is your first time using the code all resources will be new to add (nothing to destroy or update in place).
* If no errors on the plan, and looks good to you the actions that will be executed then run "terraform apply"

## SSH keys

To load your ssh keys you can do so by executing:
$ eval $(ssh-agent)
$ ssh-add <priv-cert-filename>

## Terraform tfvars

A terraform.tfvars.example has been included. Copy it and rename it as terraform.tfvars with the correct values:

```
$ cat terraform.tfvars.example
gcp_project_id          = "your-project-name"
# Make sure you export this variable on your working environment before starting to use terraform for this project:
# e.g.: export "GOOGLE_APPLICATION_CREDENTIALS=/your/path/to/credentials/file.json"
gcp_credentials_file    = "your-gcpproject-service-credentials-file-path"
gcp_region              = "us-west1"
k8s_privkey           = "~/.ssh/id_rsa"
k8s_pubkey            = "~/.ssh/id_rsa.pub"
source_ext_cidr         = "your-source-public-ip"
```
## Variables to customize environment

There are some variables that you can add to your environment to extend on the customization of what you are deploying (see variables.tf for all options)

# Some Examples are:

* gcp_storage_region : In case you want to setup your bucket for terraform backend on a different region (defaults to "us")
* gce_machine_type[bastion] and gce_machine_type[k8s] : Type of GCP Compute Engine machines (default: bastion:n1-standard-1, k8s:n2-standard-4
* k8s_disk.size : Data disk size for kubernetes nodes (defaults to 10gb)
* os_disk_size : OS disk size for nodes (defaults to: bastion:20gb, k8s:30gb)
* instance_count : Number of instances for kubernetes nodes
* kubekey_version : Kubekey version to use for the install (defaults to v3.0.10)
* k8s_version : Kubernetes version to install (defaults to v1.25.3)
* kubesphere_version : Kubesphere version to install (defaults to v3.4.0)

## Notes, considerations, limitations and future work

* While this currently aims to only be an installer using kubekey to install kubesphere and kubernetes, this is intended to use just as a base for deploying other applications or services on top. The idea is in the future create other options to deploy specific stacks over this framework (such as Spark and kafka clusters)
* Currently there is no HA for kubernetes master which reason the first k8s node created is chosen as master and will have the following services:
 * K8s backend Storage: etcd
 * K8s API
 * K8s Scheduler
 * K8s Control Manager
* In the future, a probably improvement will involve to include the option to use more than one defined master for kubernetes to allow for HA.
* For the installation of the software there is a requirement to enable passwora-dless root, for production systems with stronger security requirements this will need to be adjusted after installation. In such cases though one would also have to analyze if kubekey is the right tool for this (and also kubesphere)
