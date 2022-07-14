#!/bin/bash

source ./install_docker.sh

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
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
}

install_kubernetes () {
    update_system
    apt-get install kubelet kubeadm kubectl -y &> /dev/null
    apt-mark hold kubelet kubeadm kubectl
    swapoff -a
}

start_kubernetes () {
    kubeadm config images pull
    kubeadm init
    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
}

reboot_containerd () {
    rm /etc/containerd/config.toml
    systemctl restart containerd
}

reboot_containerd
add_ppa_kubernetes
install_kubernetes
start_kubernetes
