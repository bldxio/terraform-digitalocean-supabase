## Packer configuration
packer {
  required_version = "~> 1.9.1"
  required_plugins {
    digitalocean = {
      version = ">= 1.0.4"
      source  = "github.com/digitalocean/digitalocean"
    }
  }
}

# Variables
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

variable "domain" {
  description = "The domain of the supabase instance"
  type        = string
}

variable "droplet_image" {
  description = "The Droplet image ID or slug."
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "droplet_size" {
  description = "The unique slug that identifies the type of Droplet."
  type        = string
  default     = "s-4vcpu-8gb"
}

# HCP Packer registry variables
variable "service" {
  description = "The name of the HCP Packer bucket defined by the using service"
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

variable "github_actor" {
  description = "GitHub username of the person who triggered the workflow."
  type        = string
  default     = "unknown"
}

variable "environment" {
  description = "Environment name derived from the branch."
  type        = string
}

variable "org" {
  description = "The organization or entity that owns the resources"
  type        = string
}

locals {
  timestamp     = regex_replace(timestamp(), "[- TZ:]", "")
  snapshot_name = "supabase-${var.environment}-${local.timestamp}"
  tags = [
    "org:${var.org}",
    "deployBy:${var.github_actor}",
    "owner:${var.github_actor}",
    "name:supabase-do-packer",
    "service:supabase",
    "service:digitalocean",
    "service:packer",
    "env:${var.environment}"
  ]
}

# Source configuration
source "digitalocean" "supabase" {
  image         = var.droplet_image # Using the variable directly instead of HCP data source
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
    bucket_name = "${var.service}-${var.environment}"
    description = "Supabase image for DigitalOcean droplets"

    build_labels = {
      "build-time"   = timestamp()
      "build-source" = "packer"
      "owner"        = var.github_actor
      "deployedBy"   = var.github_actor
      "os"           = var.droplet_image
      "region"       = var.region
      "env"          = var.environment
      "org"          = var.org
      "service"      = var.service
    }
  }

  # Copy all files from supabase directory first
  provisioner "file" {
    source      = "./supabase"
    destination = "/root"
  }

  # Process the template and overwrite the existing file
  provisioner "file" {
    content = templatefile("./supabase/supabase.subdomain.conf.pkrtpl.hcl", {
      environment = var.environment
    })
    destination = "/root/supabase/supabase.subdomain.conf"
  }

  provisioner "shell" {
    script = "./scripts/setup.sh"
  }
}
