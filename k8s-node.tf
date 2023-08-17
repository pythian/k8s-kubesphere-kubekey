resource "google_compute_disk" "k8s-disk" {
  count        = "${var.instance_count}"
  name         = "k8s-0${count.index+1}-datadisk"
  zone         = "${google_compute_subnetwork.subnet_k8s.region}-b"
  type         = "${var.k8s_disk["type"]}"
  size         = "${var.k8s_disk["size"]}"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_compute_instance" "k8s-node" {
  name         = "k8s-0${count.index+1}"
  zone         = "${google_compute_subnetwork.subnet_k8s.region}-b"
  machine_type = "${var.gce_machine_type["k8s"]}"

  #depends_on = [google_compute_instance.bastion]
  deletion_protection = false
  lifecycle {
    prevent_destroy = false
  }
  allow_stopping_for_update = true

  tags         = [
    "k8s-nodes"
  ]

  boot_disk {
    initialize_params {
      image = "${var.gce_image_name["k8s"]}"
      size  = "${var.os_disk_size["k8s"]}"
    }
  }

  attached_disk {
    source      = "${element(google_compute_disk.k8s-disk.*.self_link, count.index)}"
    device_name = "${element(google_compute_disk.k8s-disk.*.name, count.index)}"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet_k8s.self_link}"
  }

  metadata = {
    ssh-keys = "${var.k8s_user}:${file(var.k8s_pubkey)}"
  }

  service_account {
    email  = "${google_service_account.k8s_account.email}"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  count = "${var.instance_count}"
}

resource "null_resource" "k8s-data-mount" {

  depends_on = [google_compute_instance.k8s-node, google_compute_disk.k8s-disk]

  connection {
        agent = false
        user = "${var.k8s_user}"
        private_key = "${file(var.k8s_privkey)}"
        timeout = "2m"
        host = "${element(google_compute_instance.k8s-node.*.network_interface.0.network_ip, count.index)}"
        bastion_host = "${google_compute_address.bastion_public_ip.address}"
        bastion_user = "${var.k8s_user}"
        bastion_private_key = "${file(var.k8s_privkey)}"
   }

  provisioner "file" {
    source      = "scripts/k8s_disk_mount.sh"
    destination = "/tmp/k8s_disk_mount.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/k8s_disk_mount.sh",
      "sudo /tmp/k8s_disk_mount.sh",
    ]
  }
  count = "${var.instance_count}"
}

data "template_file" "k8s_nodes_list" {
  template = file("templates/deployment-hosts.yml.tpl")

  vars = {
    k8s_hostnames             = join(",", google_compute_instance.k8s-node[*].name)
    k8s_internal_ip_addresses = join(",", google_compute_instance.k8s-node[*].network_interface.0.network_ip)
    k8s_user		      = "${var.k8s_user}"
  }

  depends_on = [google_compute_instance.k8s-node]
}

