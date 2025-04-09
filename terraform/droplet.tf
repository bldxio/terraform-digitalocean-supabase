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
      tailscale up --authkey=${tailscale_tailnet_key.supabase.key} --hostname=supastudio --advertise-tags=tag:${var.environment},tag:server --accept-dns=true

      # Get Tailscale IP for studio binding
      TAILSCALE_IP=$(tailscale ip -4)
      echo "TAILSCALE_IP=$TAILSCALE_IP" >> /root/supabase/.env

      # We no longer need to add hosts entry as we'll use the Tailscale MagicDNS name (supastudio)
      mkdir -p /mnt/supabase_volume
      sudo mount -o defaults,nofail,discard,noatime /dev/disk/by-id/scsi-0DO_Volume_supabase-volume /mnt/supabase_volume
      sleep 10
      mkdir -p /mnt/supabase_volume/supabase/data
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
  count = var.ssh_pub_file == "" ? 0 : 1

  name       = "Supabase Droplet SSH Key"
  public_key = file(var.ssh_pub_file)
}
