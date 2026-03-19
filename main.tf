terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.69"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_host_address
  api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure  = true
}
