# data "digitalocean_domain" "this" {
#   name = var.domain
# }

data "cloudflare_zones" "this" {
  filter {
    name = var.domain
  }
}

# Wait for the Volume to mount to the Droplet to ensure "Resource Busy" error is not encountered
resource "time_sleep" "wait_20_seconds" {
  depends_on = [digitalocean_droplet.this]

  create_duration = "20s"
}


resource "digitalocean_reserved_ip" "this" {
  droplet_id = digitalocean_droplet.this.id
  region     = var.region

  depends_on = [
    time_sleep.wait_20_seconds
  ]
}

resource "cloudflare_record" "a_record" {
  zone_id = var.cloudflare_zone_id
  type    = "A"
  name    = "supabase"
  value   = digitalocean_reserved_ip.this.ip_address
}

# resource "cloudflare_record" "a_record" {
#   zone_id = data.cloudflare_zones.this.zones[0].id
#   name    = "supabase"
#   value   = digitalocean_reserved_ip.this.ip_address
#   type    = "A"
#   ttl     = 1
# }

resource "digitalocean_firewall" "this" {
  name        = "supabase"
  droplet_ids = [digitalocean_droplet.this.id]

  tags = local.tags

  dynamic "inbound_rule" {
    for_each = local.inbound_rule == null ? [] : local.inbound_rule

    content {
      protocol         = inbound_rule.value.protocol
      port_range       = inbound_rule.value.port_range
      source_addresses = inbound_rule.value.source_addresses
    }
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
