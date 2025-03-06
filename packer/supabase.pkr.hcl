packer {
  required_version = "~> 1.9.1"

  required_plugins {
    digitalocean = {
      version = "1.1.1"
      source  = "github.com/digitalocean/digitalocean"
    }
    hcp = {
      version = ">= 0.5.0"
      source  = "github.com/hashicorp/hcp"
    }
  }
}

# Set the variable value in the supabase.auto.pkvars.hcl file
# or use -var "do_token=..." CLI option
variable "do_token" {
  description = "DO API token with read and write permissions."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The region where the Droplet will be created."
  type        = string
  default     = "sfo3"
}

variable "droplet_image" {
  description = "The Droplet image ID or slug. This could be either image ID or droplet snapshot ID."
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "droplet_size" {
  description = "The unique slug that identifies the type of Droplet."
  type        = string
  default     = "s-2vcpu-4gb"
}

# HCP Packer registry variables
variable "hcp_bucket_name" {
  description = "The name of the HCP Packer bucket where image metadata will be stored."
  type        = string
  default     = "supabase"
}

variable "hcp_client_id" {
  description = "The HCP client ID for authentication."
  type        = string
  sensitive   = true
}

variable "hcp_client_secret" {
  description = "The HCP client secret for authentication."
  type        = string
  sensitive   = true
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")

  snapshot_name = "supabase-${local.timestamp}"

  tags = [
    "supabase",
    "digitalocean",
    "packer"
  ]
}

source "digitalocean" "supabase" {
  image         = var.droplet_image
  region        = var.region
  size          = var.droplet_size
  snapshot_name = local.snapshot_name
  tags          = local.tags
  ssh_username  = "root"
  api_token     = var.do_token
}

build {
  sources = ["source.digitalocean.supabase"]

  # HCP Packer registry configuration
  hcp_packer_registry {
    bucket_name = var.hcp_bucket_name
    description = "Supabase image for DigitalOcean droplets"

    bucket_labels = {
      "owner"          = "nathan@bldx.ai"
      "os"             = "ubuntu"
      "ubuntu-version" = "22.04"
      "region"         = var.region
    }

    build_labels = {
      "build-time"   = timestamp()
      "build-source" = "packer"
    }
  }

  provisioner "file" {
    source      = "./supabase"
    destination = "/root"
  }

  provisioner "shell" {
    script = "./scripts/setup.sh"
  }
}
