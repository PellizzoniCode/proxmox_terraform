variable "pm_api_token_id" {
  type    = string
  default = "<generated_token_id_on_proxmox_ui>" #Example: "terraform@pve!terraform-token"
}

variable "pm_api_token_secret" {
  type    = string
  default = "<generated_token_secret_on_proxmox_ui>" #Example: "abc123def456ghi789jkl012mno345pq"
}

#### Global Parameters ####
variable "bridge_network" {
  type    = string
  default = "vmbr0" #Update with your bridge network name if different (e.g. vmbr1)
}

variable "bridge_cidr_range" {
  type    = string
  default = "<your_bridge_cidr_range>" #Example: "192.168.1.0/24"
}

variable "ssh_keys" {
  type    = string
  default = "<your_ssh_public_keys>" #Example: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3... user@hostname"
}

variable "ciuser" {
  type    = string
  default = "proxuser" #Update with your desired cloud-init username
}

variable "target_node" {
  type    = string
  default = "proxmox-node1" #Update with the name of the Proxmox node where you want to create the VMs
}

variable "template_vmid" {
  type    = number
  default = 9000 #if you ran the template creation script, this should be 9000, otherwise update with the VMID of your cloud-init template
}

#### Control Plane Parameters ###
variable "control_plane_nr" {
  type    = number
  default = 3 #Update with the number of control plane nodes you want to create
}

variable "control_plane_id_range" {
  type    = number
  default = 400 #Update with the range of IDs for control plane nodes this will generate something like 400, 401, 402 for 3 control plane nodes. Make sure this range does not overlap with any existing VMIDs in your Proxmox cluster.
}

variable "control_plane_network_range" {
  type    = number
  default = 60 #The IP for three control planes will end with .60, .61, .62 if you use the default bridge_cidr_range of 192.168.1.0/24
}

variable "control_plane_naming" {
  type    = string
  default = "cp" #This will generate VM names like cp-400, cp-401, cp-402 for the control plane nodes. Update if you want a different naming convention.
}

variable "control_plane_cores" {
  type    = number
  default = 4 #Update with the number of CPU cores you want to allocate to each control plane node
}

variable "control_plane_sockets" {
  type    = number
  default = 1 #Update with the number of CPU sockets you want to allocate to each control plane node
}

variable "control_plane_memory" {
  type    = number
  default = 8192 #Update with the amount of RAM in MB you want to allocate to each control plane node (e.g. 8192 for 8GB) Feel free to use less
}

variable "control_plane_disksize" {
  type    = number
  default = 30 #Update with the disk size in GB you want to allocate to each control plane node (e.g. 30 for 30GB) Feel free to use less
}

#### Worker Node Parameters ###
variable "worker_nr" {
  type    = number
  default = 3 #Update with the number of worker nodes you want to create
}

variable "worker_id_range" {
  type    = number
  default = 500 #Update with the range of IDs for worker nodes this will generate something like 500, 501, 502 for 3 worker nodes. Make sure this range does not overlap with any existing VMIDs in your Proxmox cluster.
}

variable "worker_network_range" {
  type    = number
  default = 70 #The IP for three worker nodes will end with .70, .71, .72 if you use the default bridge_cidr_range of 192.168.1.0/24
}

variable "worker_naming" {
  type    = string
  default = "worker" #This will generate VM names like worker-500, worker-501, worker-502 for the worker nodes. Update if you want a different naming convention.
}

variable "worker_cores" {
  type    = number
  default = 2 #Update with the number of CPU cores you want to allocate to each worker node
}

variable "worker_sockets" {
  type    = number
  default = 1 #Update with the number of CPU sockets you want to allocate to each worker node
}

variable "worker_memory" {
  type    = number
  default = 4096 #Update with the amount of RAM in MB you want to allocate to each worker node (e.g. 4096 for 4GB) Feel free to use less
}

variable "worker_disksize" {
  type    = number
  default = 20 #Update with the disk size in GB you want to allocate to each worker node (e.g. 20 for 20GB) Feel free to use less
}

variable "proxmox_host_address" {
  type        = string
  description = "Proxmox VE API endpoint URL (e.g. https://192.168.0.50:8006/)"
  default     = "https://192.168.0.50:8006/" #Update with your Proxmox VE API endpoint
}
