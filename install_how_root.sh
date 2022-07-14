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
    install_packages_apt "apt-transport-https ca-certificates curl"
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
}

install_kubernetes () {
    update_system
    install_packages_apt "kubelet kubeadm kubectl"
    apt-mark hold kubelet kubeadm kubectl
    swapoff -a
}

start_kubernetes () {
    kubeadm config images pull
    kubeadm init
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
}

add_ppa_kubernetes
install_kubernetes
start_kubernetes
