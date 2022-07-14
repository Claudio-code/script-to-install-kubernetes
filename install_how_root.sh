#!/bin/bash

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

add_ppa_kubernetes () {
    update_system
    apt-get install -y apt-transport-https ca-certificates curl
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
}

remove_locks () {
    rm /var/lib/dpkg/lock-frontend
    rm /var/cache/apt/archives/lock
}

update_system () {
    remove_locks
    apt-get update && apt-get upgrade -y
}

install_kubernetes () {
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
    swapoff -a
}

update_system
add_ppa_kubernetes
install_kubernetes
