spec:
  hosts:
  %{ for idx in split(",", k8s_hostnames) ~}
  - {name: ${idx}, address: ${element(split(",", k8s_internal_ip_addresses), index(split(",", k8s_hostnames), idx))}, internalAddress: ${element(split(",", k8s_internal_ip_addresses), index(split(",", k8s_hostnames), idx))}, user: root, privateKeyPath: "~/.ssh/id_rsa"}
  %{ endfor ~}
roleGroups:
    etcd:
    - ${element(split(",", k8s_hostnames), 0)}
    control-plane:
    - ${element(split(",", k8s_hostnames), 0)}
    worker:
    %{ for hostname in slice(split(",", k8s_hostnames), 1, length(split(",", k8s_hostnames))) ~}
    - ${hostname}
    %{ endfor ~}
