#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

println () {
  local message="$1"
  echo -e "${GREEN}[INFO]${NC} - ${message}"
}

multipass_install () {
    println "Installing multipass."
    sudo snap refresh &> /dev/null
    sudo snap install multipass &> /dev/null
}

create_clusters () {
    println "Creating three virtual-machines to use in your cluster."
    multipass launch -n kube-node-master -m 4294967296 -c 2 &> /dev/null
    multipass launch -n kube-node-one -m 4294967296 -c 2 &> /dev/null
    multipass launch -n kube-node-two -m 4294967296 -c 2 &> /dev/null
}

update_cluster_nodes () {
    println "Updating three virtual-machines."
    multipass exec kube-node-two -- bash -c 'sudo apt update && sudo apt upgrade -y' &> /dev/null
    multipass exec kube-node-one -- bash -c 'sudo apt update && sudo apt upgrade -y' &> /dev/null
    multipass exec kube-node-master -- bash -c 'sudo apt update && sudo apt upgrade -y' &> /dev/null
}

add_kube_config_in_nodes () {
    println "Adding env kubeconfig in three virtual-machines."
    multipass exec kube-node-master -- bash -c "echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> .bashrc" &> /dev/null
    multipass exec kube-node-one -- bash -c "echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> .bashrc" &> /dev/null
    multipass exec kube-node-two -- bash -c "echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> .bashrc" &> /dev/null
}

add_kubernetes_in_two_node_clusters () {
    println "Adding k8s in two virtual-machines."
    multipass exec kube-node-two -- bash -c 'git clone https://github.com/Claudio-code/script-to-install-kubernetes.git && cd ./script-to-install-kubernetes && sudo ./install_how_root_node.sh' &> /dev/null
    multipass exec kube-node-one -- bash -c 'git clone https://github.com/Claudio-code/script-to-install-kubernetes.git && cd ./script-to-install-kubernetes && sudo ./install_how_root_node.sh' &> /dev/null
}

added_nodes_to_cluster () {
    println "Adding token to connect nodes in master."
    local kubeadm_token="$1"
    multipass exec kube-node-two -- bash -c "sudo $kubeadm_token" &> /dev/null
    multipass exec kube-node-one -- bash -c "sudo $kubeadm_token" &> /dev/null
}

add_kubernetes_in_cluster_master () {
    println "Adding k8s in node-master and creating kube token."
    multipass exec kube-node-master -- bash -c "git clone https://github.com/Claudio-code/script-to-install-kubernetes.git && cd ./script-to-install-kubernetes && sudo ./install_how_root.sh" &> /dev/null
    local command_output=`multipass exec kube-node-master -- bash -c "sudo kubeadm token create --print-join-command"`
    added_nodes_to_cluster "$command_output"
}

multipass_install
create_clusters
update_cluster_nodes
add_kube_config_in_nodes
add_kubernetes_in_two_node_clusters
add_kubernetes_in_cluster_master
