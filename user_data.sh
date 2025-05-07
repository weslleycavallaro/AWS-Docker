#!/bin/bash
set -e

sudo mkdir -p /home/aws
sudo chown ubuntu:ubuntu /home/aws


sudo apt update -y
sudo apt install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install -y \
  awscli \
  nfs-common \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin


# Variáveis
cat <<EOF > $USER_HOME/var.env
WORDPRESS_DB_HOST=db-projeto-docker.12345.us-east-1.rds.amazonaws.com:3306
WORDPRESS_DB_USER=admin
WORDPRESS_DB_PASSWORD=senha#senha
WORDPRESS_DB_NAME=DBPROJETODOCKER
WORDPRESS_SITEURL=http://projetodocker-12345.us-east-1.elb.amazonaws.com
WORDPRESS_HOME=http://projetodocker-12345.us-east-1.elb.amazonaws.com
EFS_DNS=fs-12345.efs.us-east-1.amazonaws.com
EOF

source /home/aws/var.env


# EFS
sudo mkdir -p /mnt/efs/wordpress
sudo mount -t nfs4 -o nfsvers=4.1,tcp,hard,timeo=600,retrans=2 "$EFS_DNS":/ /mnt/efs
sudo chown -R 33:33 /mnt/efs/wordpress


# Compose
cat <<EOF > /home/aws/compose.yml
services:
  wordpress:
    image: wordpress
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: ${WORDPRESS_DB_HOST}
      WORDPRESS_DB_USER: ${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: ${WORDPRESS_DB_PASSWORD}
      WORDPRESS_DB_NAME: ${WORDPRESS_DB_NAME}
      WORDPRESS_SITEURL: ${WORDPRESS_SITEURL}
      WORDPRESS_HOME: ${WORDPRESS_HOME}
    volumes:
      - /mnt/efs/wordpress:/var/www/html
EOF


cd /home/aws
sudo docker compose up -d
