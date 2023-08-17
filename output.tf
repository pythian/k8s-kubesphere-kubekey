output "bastion_external_ip_address" {
  value = "${google_compute_address.bastion_public_ip.address}"
}

output "kubesphere_internal_details" {
  value ={
    kubesphere_console_url: "http://10.0.11.4:30880",
    kubesphere_initial_username: "admin"
    kubesphere_initial_password: "P@88w0rd"
  }
}
