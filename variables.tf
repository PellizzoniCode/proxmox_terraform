variable "pm_api_token_id" {}

variable "pm_api_token_secret" {}

variable "bridge_network" {}

variable "bridge_cidr_range" {}

variable "ssh_keys" {}

variable "ciuser" {}

variable "target_node" {}

variable "template_vmid" {
  type        = number
  description = "VMID of the debian12-cloud-init template in Proxmox"
}

variable "control_plane_nr" {}

variable "control_plane_id_range" {}

variable "control_plane_network_range" {}

variable "control_plane_naming" {}

variable "control_plane_cores" {}

variable "control_plane_sockets" {}

variable "control_plane_memory" {}

variable "control_plane_disksize" {
  type        = number
  description = "Disk size in GB"
}

variable "worker_nr" {}

variable "worker_id_range" {}

variable "worker_network_range" {}

variable "worker_naming" {}

variable "worker_cores" {}

variable "worker_sockets" {}

variable "worker_memory" {}

variable "worker_disksize" {
  type        = number
  description = "Disk size in GB"
}

variable "proxmox_host_address" {
  type        = string
  description = "Proxmox VE API endpoint URL (e.g. https://192.168.0.50:8006/)"
  default     = "https://192.168.0.50:8006/" #Update with your Proxmox VE API endpoint
}
