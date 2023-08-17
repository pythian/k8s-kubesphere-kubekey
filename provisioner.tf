resource "null_resource" "bastion_initialization" {

  depends_on = [google_compute_instance.k8s-node, google_compute_instance.bastion]

  connection {
        agent = true
        timeout = "2m"
        host = "${google_compute_address.bastion_public_ip.address}"
        user = "${var.k8s_user}"
        private_key = "${file(var.k8s_privkey)}"
#        bastion_host = "${google_compute_address.bastion_public_ip.address}"
#        bastion_user = "${var.k8s_user}"
#        bastion_private_key = "${file(var.k8s_privkey)}"
   }

  provisioner "file" {
    source      = "${var.k8s_privkey}"
    destination = "/home/${var.k8s_user}/.ssh/id_rsa"
  }

  provisioner "file" {
       source      = "scripts/add_hosts_to_deployment.py"
       destination  = "/home/${var.k8s_user}/add_hosts_to_deployment.py"
  }

  provisioner "file" {
       source      = "scripts/verify_results.py"
       destination  = "/home/${var.k8s_user}/verify_results.py"
  }

  provisioner "remote-exec" {
    inline = [
    "sudo apt-get update",
#    "sudo apt-get dist-upgrade -y --force-yes",
    "sudo DEBIAN_FRONTEND=noninteractive apt-get install curl openssl tar ntp python3-pip -y",
    "sudo DEBIAN_FRONTEND=noninteractive apt-get install socat conntrack ebtables ipset ipvsadm -y",
    "pip3 install PyYAML",
    "sudo echo -e 'StrictHostKeyChecking no\n' >> ~/.ssh/config; sudo chmod 600 ~/.ssh/config",
    "sudo chmod 600 ~/.ssh/id_rsa",
    "sudo ssh-keygen -t rsa -q -f /root/.ssh/id_rsa -N ''",
    "sudo cp --verbose /root/.ssh/id_rsa.pub /tmp/bastion_root.pub",
    "sudo cp --verbose /root/.ssh/id_rsa /tmp/bastion_root",
    "sudo chown -v ${var.k8s_user} /tmp/bastion_root.pub",
    "sudo chown -v ${var.k8s_user} /tmp/bastion_root",
    "sudo cat /root/.ssh/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys > /dev/null"
    ]
  }

}

resource "null_resource" "copy_file_to_nodes" {
  count = length(google_compute_instance.k8s-node.*.network_interface.0.network_ip)
  depends_on = [null_resource.bastion_initialization]

  provisioner "remote-exec" {
    connection {
        agent = true
        timeout = "2m"
        host = "${google_compute_address.bastion_public_ip.address}"
        user = "${var.k8s_user}"
        private_key = "${file(var.k8s_privkey)}"
#        bastion_host = "${google_compute_address.bastion_public_ip.address}"
#        bastion_user = "${var.k8s_user}"
#        bastion_private_key = "${file(var.k8s_privkey)}"
    }

    inline = [
      format("scp /tmp/bastion_root.pub %s:/tmp/bastion_root.pub", google_compute_instance.k8s-node[count.index].network_interface.0.network_ip)
    ]
  }
}

resource "null_resource" "k8s_initialization" {

  depends_on = [null_resource.bastion_initialization]

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
    source      = "${var.k8s_privkey}"
    destination = "/home/${var.k8s_user}/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
    "sudo apt-get update",
#    "sudo apt-get dist-upgrade -y --force-yes",
    "sudo DEBIAN_FRONTEND=noninteractive apt-get install curl openssl tar ntp -y",
    "sudo DEBIAN_FRONTEND=noninteractive apt-get install socat conntrack ebtables ipset ipvsadm -y",
    ]
  }

  count = "${var.instance_count}"
}

resource "null_resource" "k8s-bastion-root-key" {

  depends_on = [null_resource.k8s_initialization]

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

  provisioner "remote-exec" {
    inline = [
      "cat /tmp/bastion_root.pub | sudo tee -a /root/.ssh/authorized_keys > /dev/null",
      "rm /tmp/bastion_root.pub"
    ]
  }

  count = "${var.instance_count}"
}

resource "null_resource" "install_k8s" {
  depends_on = [null_resource.k8s-bastion-root-key]

  connection {
        agent = true
        timeout = "2m"
        host = "${google_compute_address.bastion_public_ip.address}"
        user = "${var.k8s_user}"
        private_key = "${file(var.k8s_privkey)}"
   }

   provisioner "remote-exec" {
    inline = [
    "curl -sfL https://get-kk.kubesphere.io | VERSION=${var.kubekey_version} sh -",
    "chmod +x kk",
    "./kk create config -f deployment-kubesphere.yml --with-kubernetes ${var.k8s_version} --with-kubesphere ${var.kubesphere_version}",
    "python3 add_hosts_to_deployment.py",
    "python3 verify_results.py",
    "sudo ./kk create cluster -f updated-kubesphere.yml -y"
    ]
  }

}

resource "null_resource" "bastion_cleanup" {

  depends_on = [null_resource.k8s-bastion-root-key]

  connection {
        agent = true
        timeout = "2m"
        host = "${google_compute_address.bastion_public_ip.address}"
        user = "${var.k8s_user}"
        private_key = "${file(var.k8s_privkey)}"
#        bastion_host = "${google_compute_address.bastion_public_ip.address}"
#        bastion_user = "${var.k8s_user}"
#        bastion_private_key = "${file(var.k8s_privkey)}"
   }

 provisioner "remote-exec" {
    inline = [
    "rm -f /tmp/bastion_root.pub"
    ]
  }

}
