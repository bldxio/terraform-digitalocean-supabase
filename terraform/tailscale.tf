resource "tailscale_tailnet_key" "supabase" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  expiry        = 7776000 # 90 days
  description   = "auth key for tailscale automated server binding"
  tags = [
    "tag:server",
    "tag:${var.environment}"
  ]
}

