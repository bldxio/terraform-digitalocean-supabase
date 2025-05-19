# Assign resources to the existing "prd" project
# This is used when projects are managed outside of Terraform

# Local variable to determine if we should assign resources to a specific project
locals {
  assign_to_project = var.do_project_id != ""
}

# Wait for resources to be fully created before assigning them to a project
resource "time_sleep" "wait_for_resources" {
  count = local.assign_to_project ? 1 : 0

  depends_on = [
    digitalocean_droplet.this,
    digitalocean_spaces_bucket.this,
    digitalocean_volume.this,
    digitalocean_reserved_ip.this
  ]

  create_duration = "15s"
}

# Assign resources to the specified project
resource "digitalocean_project_resources" "prd" {
  count = local.assign_to_project ? 1 : 0

  project = var.do_project_id
  resources = [
    digitalocean_droplet.this.urn,
    digitalocean_spaces_bucket.this.urn,
    digitalocean_volume.this.urn,
    digitalocean_reserved_ip.this.urn
  ]

  depends_on = [
    time_sleep.wait_for_resources
  ]
}

