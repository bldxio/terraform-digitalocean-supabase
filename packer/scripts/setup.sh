#!/bin/bash
# A Bash script to install Docker and Docker Compose on Ubuntu 22

# fix: debconf: unable to initialize frontend: Dialog
echo set debconf to Noninteractive
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

# Install Docker

# Update existing packages:
sudo apt-get -y update
# fix: Could not get lock /var/lib/dpkg/lock-frontend. It is held by process
while sudo lsof /var/lib/dpkg/lock-frontend; do sleep 10; done

sudo apt-get -y install \
    ca-certificates \
    curl \
    gnupg
# Add the GPG key for the official Docker repository to the system:
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add the Docker repository to APT sources:
echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

# Install Docker:
sudo apt-get -y update
while sudo lsof /var/lib/dpkg/lock-frontend; do sleep 10; done

sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify the template substitution happened correctly in the NGINX config
echo "Verifying NGINX config has environment variable:"
grep -i "environment" /root/supabase/supabase.subdomain.conf || echo "WARNING: Environment variable not found in config!"

# Test your installation:
docker compose version
