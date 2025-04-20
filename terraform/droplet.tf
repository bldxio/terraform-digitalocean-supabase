data "hcp_packer_artifact" "supabase" {
  bucket_name  = "supabase-${var.environment}"
  channel_name = "latest"
  platform     = "digitalocean"
  region       = "sfo3"
}

data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = false
  part {
    content_type = "text/cloud-config"
    filename     = "cloud-config.yaml"
    content      = local.cloud_config
  }
  part {
    content_type = "text/x-shellscript"
    filename     = "init.sh"
    content      = <<-EOF
      #!/bin/bash
      # Install Tailscale
      curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/oracular.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
      curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/oracular.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
      sudo apt-get update
      sudo apt-get install -y tailscale

      # Authenticate with the generated key and enable MagicDNS
      tailscale up --authkey=${tailscale_tailnet_key.supabase.key} --hostname=supastudio-${var.environment} --advertise-tags=tag:${var.environment},tag:server --accept-dns=true

      # Get Tailscale IP for studio binding
      TAILSCALE_IP=$(tailscale ip -4)
      echo "TAILSCALE_IP=$TAILSCALE_IP" >> /root/supabase/.env

      # Mount the volume first
      mkdir -p /mnt/supabase_volume
      sudo mount -o defaults,nofail,discard,noatime /dev/disk/by-id/scsi-0DO_Volume_supabase-volume /mnt/supabase_volume
      sleep 10

      # Now create directories on the mounted volume
      mkdir -p /mnt/supabase_volume/tailscale_certs
      mkdir -p /mnt/supabase_volume/supabase/data

      # After tailscale has been set up and authenticated
      # Get the Tailscale domain for supastudio
      TAILSCALE_HOSTNAME="supastudio-${var.environment}"
      TAILSCALE_DOMAIN=$(tailscale status | grep "$TAILSCALE_HOSTNAME" | awk '{print $3}')

      if [ -z "$TAILSCALE_DOMAIN" ]; then
        echo "Error: Could not determine Tailscale domain for $TAILSCALE_HOSTNAME"
        echo "Tailscale status output:"
        tailscale status
        # Wait for Tailscale to fully initialize and try again
        sleep 15
        TAILSCALE_DOMAIN=$(tailscale status | grep "$TAILSCALE_HOSTNAME" | awk '{print $3}')
        if [ -z "$TAILSCALE_DOMAIN" ]; then
          echo "Error: Still could not determine Tailscale domain after waiting. Using default domain."
          TAILSCALE_DOMAIN="$TAILSCALE_HOSTNAME.ts.net"
        fi
      fi

      echo "Using Tailscale domain: $TAILSCALE_DOMAIN"

      # Add Tailscale variables to environment file
      echo "TAILSCALE_HOSTNAME=$TAILSCALE_HOSTNAME" >> /root/supabase/.env
      echo "TAILSCALE_DOMAIN=$TAILSCALE_DOMAIN" >> /root/supabase/.env

      # Create the certificate
      echo "Requesting Tailscale certificate for $TAILSCALE_DOMAIN..."
      sudo tailscale cert $TAILSCALE_DOMAIN
      if [ $? -ne 0 ]; then
        echo "Error: Failed to obtain Tailscale certificate. Retrying after short wait..."
        sleep 10
        sudo tailscale cert $TAILSCALE_DOMAIN
      fi

      # Copy the certificates where the SWAG container can access them
      echo "Copying certificates..."
      cp -v /var/lib/tailscale/certs/* /mnt/supabase_volume/tailscale_certs/

      # Ensure the certificates are readable by the SWAG container
      chmod -R 644 /mnt/supabase_volume/tailscale_certs/

      # Verify certificates were copied correctly
      echo "Verifying certificate files:"
      ls -la /mnt/supabase_volume/tailscale_certs/

      # Start services
      cd /root/supabase
      /usr/bin/docker compose -f /root/supabase/docker-compose.yml up -d
    EOF
  }
}

resource "digitalocean_droplet" "this" {
  image      = data.hcp_packer_artifact.supabase.external_identifier
  name       = "supabase-droplet"
  region     = var.region
  size       = var.droplet_size
  monitoring = true
  backups    = var.droplet_backups
  ssh_keys   = local.ssh_fingerprints
  volume_ids = [digitalocean_volume.this.id]
  user_data  = data.cloudinit_config.this.rendered
  tags       = local.tags
  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "digitalocean_ssh_key" "this" {
  count      = var.ssh_pub_file == "" ? 0 : 1
  name       = "Supabase Droplet SSH Key"
  public_key = file(var.ssh_pub_file)
}
