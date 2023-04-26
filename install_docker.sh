#!/bin/bash

remove_locks () {
    rm /var/lib/dpkg/lock-frontend
    rm /var/cache/apt/archives/lock
}

update_system () {
    remove_locks
    apt-get update && apt-get upgrade -y
}

add_docker_official_key_and_repository () {
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    update_system
}

install_packages_apt () {
    local packages="$1"
    update_system
    apt-get install "$software" -y &> /dev/null
}

apt-get install apt-transport-https ca-certificates curl gnupg lsb-release -y &> /dev/null
add_docker_official_key_and_repository
apt-get install docker-ce docker-ce-cli containerd.io -y &> /dev/null

sudo systemctl enable docker
sudo systemctl restart docker
