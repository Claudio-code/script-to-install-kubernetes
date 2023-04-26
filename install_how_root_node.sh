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

reboot_containerd () {
    rm /etc/containerd/config.toml
    systemctl restart containerd
}

install_kubernetes () {
    reboot_containerd
    add_ppa_kubernetes
    update_system
    apt-get install kubelet kubeadm kubectl -y &> /dev/null
    apt-mark hold kubelet kubeadm kubectl
    swapoff -a

    sudo systemctl enable kubelet
    sudo systemctl restart kubelet
}

install_kubernetes
