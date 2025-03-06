packer {
  required_version = "~> 1.9.1"
  required_plugins {
    digitalocean = {
      version = "1.1.1"
      source  = "github.com/digitalocean/digitalocean"
    }
    hcp = {
      version = "~> 0.1"
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

variable "base_bucket_name" {
  description = "The name of the HCP Packer bucket where base images are stored."
  type        = string
  default     = "base-ubuntu"
}

variable "hcp_channel" {
  description = "The HCP Packer channel to use."
  type        = string
  default     = "dev"
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
  description = "Environment name derived from the branch (dev, prd, etc.)."
  type        = string
  default     = "dev"
}

# Data sources to fetch the latest base image from HCP Packer registry
data "hcp-packer-version" "base" {
  bucket_name  = var.base_bucket_name
  channel_name = var.hcp_channel
}

data "hcp-packer-artifact" "base-sfo3" {
  bucket_name         = var.base_bucket_name
  version_fingerprint = data.hcp-packer-version.base.fingerprint
  platform            = "digitalocean"
  region              = var.region
}

locals {
  timestamp     = regex_replace(timestamp(), "[- TZ:]", "")
  snapshot_name = "supabase-${var.environment}-${local.timestamp}"
  tags = [
    "supabase",
    "digitalocean",
    "packer",
    "env:${var.environment}"
  ]
}

# Define two source blocks: one for building from a standard DO image,
# and another for building from an HCP Packer registry image
source "digitalocean" "supabase-standard" {
  image         = var.droplet_image
  region        = var.region
  size          = var.droplet_size
  snapshot_name = local.snapshot_name
  tags          = local.tags
  ssh_username  = "root"
  api_token     = var.do_token
}

source "digitalocean" "supabase-hcp" {
  image         = data.hcp-packer-artifact.base-sfo3.external_identifier
  region        = var.region
  size          = var.droplet_size
  snapshot_name = local.snapshot_name
  tags          = local.tags
  ssh_username  = "root"
  api_token     = var.do_token
}

build {
  # Use the HCP source if a base image exists, otherwise use the standard source
  sources = [
    "source.digitalocean.supabase-hcp"
  ]

  # HCP Packer registry configuration
  hcp_packer_registry {
    bucket_name = var.hcp_bucket_name
    description = "Supabase image for DigitalOcean droplets"
    bucket_labels = {
      "deployer"    = var.github_actor
      "os"          = var.droplet_image
      "region"      = var.region
      "environment" = var.environment
      "base-image"  = data.hcp-packer-version.base.fingerprint
    }
    build_labels = {
      "build-time"   = timestamp()
      "build-source" = "packer"
      "created-by"   = var.github_actor
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
