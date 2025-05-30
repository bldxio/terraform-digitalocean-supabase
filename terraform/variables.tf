variable "do_token" {
  description = "DO API token with read and write permissions."
  type        = string
  sensitive   = true
}

variable "spaces_access_key_id" {
  description = "Access key ID used for Spaces API operations."
  type        = string
  sensitive   = true
}

variable "spaces_secret_access_key" {
  description = "Secret access key used for Spaces API operations."
  type        = string
  sensitive   = true
}

variable "sendgrid_api" {
  description = "SendGrid API Key."
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}

variable "openai_api_key" {
  description = "openai api key for supabase"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The region where the Droplet will be created."
  type        = string
}

variable "environment" {
  description = "The environment where the Droplet will be created."
  type        = string
}

variable "domain" {
  description = "Domain name where the Supabase instance is accessible. The final domain will be of the format `supastudio`"
  type        = string
}

variable "do_project_id" {
  description = "The ID of the DigitalOcean project to assign resources to. If not provided, resources will be assigned to the default project."
  type        = string
}

variable "site_url" {
  description = "Domain name of your application in the format."
  type        = string
}

variable "timezone" {
  description = "Timezone to use for Nginx (e.g. Europe/Amsterdam)."
  type        = string
}

variable "auth_user" {
  description = "The username for Nginx authentication."
  type        = string
  sensitive   = true
}

variable "smtp_admin_user" {
  description = "`From` email address for all emails sent."
  type        = string
}

variable "smtp_addr" {
  description = "Company Address of the Verified Sender. Max 100 characters. If more is needed use `smtp_addr_2`"
  type        = string
}

variable "smtp_city" {
  description = "Company city of the verified sender."
  type        = string
}

variable "smtp_country" {
  description = "Company country of the verified sender."
  type        = string
}

variable "droplet_image" {
  description = "The Droplet image ID or slug. This could be either image ID or droplet snapshot ID."
  type        = string
}

variable "droplet_size" {
  description = "The unique slug that identifies the type of Droplet."
  type        = string
}

variable "droplet_backups" {
  description = "Boolean controlling if backups are made. Defaults to true."
  type        = bool
  default     = true
}

variable "ssh_pub_file" {
  description = "The path to the public key ssh file. Only one of var.ssh_pub_file or var.ssh_keys needs to be specified and should be used."
  type        = string
  default     = ""
}

variable "ssh_keys" {
  description = "A list of SSH key IDs or fingerprints to enable in the format [12345, 123456]. Only one of `var.ssh_keys` or `var.ssh_pub_file` needs to be specified and should be used."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A list of the tags to be added to the default (`[\"supabase\", \"digitalocean\", \"terraform\"]`) Droplet tags."
  type        = list(string)
  default     = []
}

variable "volume_size" {
  description = "The size of the block storage volume in GiB. If updated, can only be expanded."
  type        = number
}

variable "enable_ssh" {
  description = "Boolean enabling connections to droplet via SSH by opening port 22 on the firewall."
  type        = bool
  default     = true
}

variable "ssh_ip_range" {
  description = "An array of strings containing the IPv4 addresses and/or IPv4 CIDRs from which the inbound traffic will be accepted for SSH. Defaults to ALL IPv4s but it is highly suggested to choose a smaller subset."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_db_con" {
  description = "Boolean enabling connections to database by opening port 5432 on the firewall."
  type        = bool
  default     = false
}

variable "db_ip_range" {
  description = "An array of strings containing the IPv4 addresses and/or IPv4 CIDRs from which the inbound traffic will be accepted for the Database. Defaults to ALL IPv4s but it is highly suggested to choose a smaller subset."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "spaces_restrict_ip" {
  description = "Boolean signifying whether to restrict the spaces bucket to the droplet and reserved ips (as well as the ssh ips if set) or allow all ips. (N.B. If Enabled this will also disable Bucket access from DO's UI.)"
  type        = bool
  default     = false
}

variable "tailscale_api_key" {
  description = "Tailscale API key for managing resources"
  type        = string
  sensitive   = true
}

variable "tailscale_tailnet" {
  description = "Tailscale telnet domain for managing resources"
  type        = string
}

variable "tailscale_subnet_cidr" {
  description = "CIDR range of your Tailscale network to allow studio access (e.g., '100.64.0.0/10')"
  type        = string
  default     = "100.64.0.0/10" # Default Tailscale CIDR range
}

variable "studio_port" {
  description = "Port for the Supabase Studio"
  type        = number
  default     = 3000
}

variable "studio_org" {
  description = "Organization for Studio Configuration."
  type        = string
  default     = "Default Organization"
}

variable "studio_project" {
  description = "Project for Studio Configuration."
  type        = string
  default     = "Default Project"
}

variable "smtp_host" {
  description = "The external mail server hostname to send emails through."
  type        = string
  default     = "smtp.sendgrid.net"
}

variable "smtp_port" {
  description = "Port number to connect to the external mail server on."
  type        = number
  default     = 465
}

variable "smtp_user" {
  description = "The username to use for mail server requires authentication"
  type        = string
  default     = "apikey"
}

variable "smtp_sender_name" {
  description = "Friendly name to show recipient rather than email address. Defaults to the email address specified in the `smtp_admin_user` variable."
  type        = string
  default     = ""
}

variable "smtp_addr_2" {
  description = "Company Address Line 2. Max 100 characters."
  type        = string
  default     = ""
}

variable "smtp_state" {
  description = "Company State."
  type        = string
  default     = ""
}

variable "smtp_zip_code" {
  description = "Company Zip Code."
  type        = string
  default     = ""
}

variable "smtp_nickname" {
  description = "Nickname to show recipient. Defaults to `smtp_sender_name` or the email address specified in the `smtp_admin_user` variable if neither are specified."
  type        = string
  default     = ""
}

variable "smtp_reply_to" {
  description = "Email address to show in the `reply-to` field within an email. Defaults to the email address specified in the `smtp_admin_user` variable."
  type        = string
  default     = ""
}

variable "smtp_reply_to_name" {
  description = "Friendly name to show recipient rather than email address in the `reply-to` field within an email. Defaults to `smtp_sender_name` or `smtp_reply_to` if `smtp_sender_name` is not set, or the email address specified in the `smtp_admin_user` variable if neither are specified."
  type        = string
  default     = ""
}

