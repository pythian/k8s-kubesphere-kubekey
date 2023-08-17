# Service Accounts
resource "google_service_account" "nat_gateway" {
  depends_on = [
    google_project_service.gcp_project,
  ]

  account_id   = "nat-gateway"
  display_name = "NAT Gateway"
}

resource "google_service_account" "bastion_account" {
  depends_on = [
    google_project_service.gcp_project,
  ]

  account_id   = "bastionaccount"
  display_name = "Bastion Server Account"
}

resource "google_service_account" "k8s_account" {
  depends_on = [
    google_project_service.gcp_project,
  ]

  account_id   = "k8saccount"
  display_name = "K8s Servers Account"

}
