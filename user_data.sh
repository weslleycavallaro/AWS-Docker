#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
set -e

export EFS_DNS=fs-12345.efs.us-east-1.amazonaws.com


sudo mkdir -p /home/aws
sudo chown ubuntu:ubuntu /home/aws


sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release



sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg



echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null



sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin



sudo tee /home/aws/.env > /dev/null <<EOF
WORDPRESS_DB_HOST=rdsprojetodocker.12345.us-east-1.rds.amazonaws.com:3306
WORDPRESS_DB_USER=admin
WORDPRESS_DB_PASSWORD=senha
WORDPRESS_DB_NAME=rdsprojetodocker
WORDPRESS_SITEURL=http://loadbalancer
WORDPRESS_HOME=http://loadbalancer
EOF

source /home/aws/.env



sudo mkdir -p /mnt/efs/wordpress
sudo apt-get install -y nfs-common

sudo mount -t nfs4 -o nfsvers=4.1,tcp,hard,timeo=600,retrans=2 "$EFS_DNS":/ /mnt/efs
sudo chown -R 33:33 /mnt/efs/wordpress



sudo tee /home/aws/compose.yml > /dev/null <<EOF
services:
  wordpress:
    image: wordpress
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: \${WORDPRESS_DB_HOST}
      WORDPRESS_DB_USER: \${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: \${WORDPRESS_DB_PASSWORD}
      WORDPRESS_DB_NAME: \${WORDPRESS_DB_NAME}
      WORDPRESS_SITEURL: \${WORDPRESS_SITEURL}
      WORDPRESS_HOME: \${WORDPRESS_HOME}
    volumes:
      - /mnt/efs/wordpress:/var/www/html
EOF

cd /home/aws

sudo systemctl enable docker
sudo systemctl start docker
sudo docker compose up -d