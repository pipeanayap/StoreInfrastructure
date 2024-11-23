#!/bin/bash

echo '========================================================'
echo '=== STEP 1: INSTALLING REQUIRED PACKAGES ==='
echo '========================================================'
apt-get update -y
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    unzip \
    gnupg-agent \
    software-properties-common

echo '============================================================='
echo '=== STEP 2: ADDING DOCKER GPG KEY AND REPOSITORY ==='
echo '============================================================='
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

echo '====================================='
echo '=== STEP 3: INSTALLING DOCKER ==='
echo '====================================='
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

echo '============================================='
echo '=== STEP 4: INSTALLING DOCKER-COMPOSE ==='
echo '============================================='
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo '============================================================='
echo '=== STEP 5: ENABLING DOCKER AT STARTUP ==='
echo '============================================================='
systemctl enable docker
systemctl start docker

echo '========================================================='
echo '=== STEP 6: ADDING CURRENT USER TO DOCKER GROUP ==='
echo '========================================================='
CURRENT_USER=$(whoami)
usermod -aG docker "$CURRENT_USER"

echo '========================================='
echo '=== STEP 7: INSTALLING CTOP TOOL ==='
echo '========================================='
wget -qO - https://azlux.fr/repo.gpg.key | apt-key add -
echo "deb http://packages.azlux.fr/debian/ stable main" | tee /etc/apt/sources.list.d/azlux.list
apt-get update -y
apt-get install -y docker-ctop

echo '=============================================================='
echo '=== DOCKER INSTALLATION COMPLETED SUCCESSFULLY ==='
echo '=============================================================='
