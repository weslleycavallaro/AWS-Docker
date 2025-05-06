#!/bin/bash
set -e

sudo apt update -y && sudo apt install -y \
  awscli \
  ca-certificates \
  curl \
  gnupg \
  nfs-common \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

cat <<EOF > /home/aws/var.env
WORDPRESS_DB_HOST=db-projeto-docker.cpim24s04axt.us-east-1.rds.amazonaws.com:3306
WORDPRESS_DB_USER=weslley
WORDPRESS_DB_PASSWORD=teste#teste
WORDPRESS_DB_NAME=DBPROJETODOCKER
WORDPRESS_SITEURL=http://projetodocker-1253802345.us-east-1.elb.amazonaws.com
WORDPRESS_HOME=http://projetodocker-1253802345.us-east-1.elb.amazonaws.com
EFS_DNS=fs-0644d31a54d3cd896.efs.us-east-1.amazonaws.com
EOF

set -a
source /home/aws/var.env
set +a

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo mkdir -p /mnt/efs/wordpress
sudo mount -t nfs4 -o nfsvers=4.1,tcp,hard,timeo=600,retrans=2 "$EFS_DNS":/ /mnt/efs

sudo chown -R 33:33 /mnt/efs/wordpress

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
