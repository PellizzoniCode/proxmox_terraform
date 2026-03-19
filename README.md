# Proxmox Kubernetes Cluster with Terraform

Terraform project that provisions a Kubernetes-ready cluster on [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment) using the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest) provider. It creates control-plane and worker VMs from a Debian 12 cloud-init template and generates an Ansible inventory file compatible with [Kubespray](https://github.com/kubernetes-sigs/kubespray).

## Architecture

| Role          | Default Count | VMID Range | IP Range (last octet) |
| ------------- | ------------- | ---------- | --------------------- |
| Control Plane | 3             | 401–403    | .60 – .62             |
| Worker        | 3             | 501–503    | .70 – .72             |

All VMs are full clones of a Debian 12 cloud-init template, configured with static IPs, SSH key injection, and the QEMU guest agent enabled.

## Prerequisites

- **Proxmox VE** host with API token access
- **Terraform** >= 1.0
- A **Debian 12 cloud-init template** on your Proxmox node (see below)

## File Overview

| File                          | Purpose                                                           |
| ----------------------------- | ----------------------------------------------------------------- |
| `main.tf`                     | Provider configuration (bpg/proxmox ~> 0.69)                      |
| `variables.tf`                | All configurable variables with sensible defaults                 |
| `terraform.tfvars`            | Your environment-specific values (git-ignored)                    |
| `control-planes.tf`           | Control-plane VM resources                                        |
| `worker.tf`                   | Worker VM resources                                               |
| `inventory.tf`                | Generates the Ansible inventory from VM outputs                   |
| `inventory.tmpl`              | Template for the Ansible inventory file                           |
| `inventory.ini`               | Generated Ansible inventory (Kubespray-compatible)                |
| `create-debian12-template.sh` | Helper script to build a Debian 12 cloud-init template on Proxmox |

## Getting Started

### 1. Create the VM Template

SSH into your Proxmox host and run the helper script:

```bash
# Uses VMID 9000 and local-lvm by default
./create-debian12-template.sh

# Or specify custom VMID and storage
./create-debian12-template.sh 9000 local-lvm
```

This downloads the Debian 12 cloud image, installs `qemu-guest-agent` into it, and converts it to a Proxmox template.

### 2. Create a Proxmox API Token

1. In the Proxmox UI, go to **Datacenter > Permissions > API Tokens**.
2. Create a token for your user (e.g. `user@pam!terraform_key`).
3. Grant the token the required permissions (VM management, datastore access).

### 3. Configure Variables

Copy the example or create your own `terraform.tfvars`:

```hcl
# Proxmox connection
pm_api_token_id      = "user@pam!terraform_key"
pm_api_token_secret  = "your-token-secret-here"
proxmox_host_address = "https://your-proxmox-host:8006/"

# Global
target_node       = "your-node-name"
bridge_network    = "vmbr0"
bridge_cidr_range = "192.168.1.0/24"
ciuser            = "kubeuser"
ssh_keys          = "ssh-ed25519 AAAA... user@host"

# Control plane nodes
control_plane_nr            = 3
control_plane_id_range      = 400
control_plane_network_range = 60
control_plane_naming        = "k8s-master"
control_plane_cores         = 2
control_plane_memory        = 4096
control_plane_disksize      = 30
template_vmid               = 9000

# Worker nodes
worker_nr            = 3
worker_id_range      = 500
worker_network_range = 70
worker_naming        = "k8s-worker"
worker_cores         = 2
worker_memory        = 4096
worker_disksize      = 50
```

### 4. Deploy

```bash
terraform init
terraform plan
terraform apply
```

After a successful apply, `inventory.ini` is generated with all node IPs and roles, ready for Kubespray.

### 5. Bootstrap Kubernetes (optional)

Use the generated inventory with Kubespray:

```bash
cd kubespray
ansible-playbook -i ../inventory.ini cluster.yml -b
```

## Customization

- **Node counts**: adjust `control_plane_nr` and `worker_nr`.
- **Resources**: tune `*_cores`, `*_memory`, and `*_disksize` variables per role.
- **IP addressing**: change `*_network_range` to shift the starting IP within your CIDR.
- **VMID ranges**: update `*_id_range` to avoid conflicts with existing VMs.
- **Naming**: set `control_plane_naming` and `worker_naming` for custom VM name prefixes.

## Teardown

```bash
terraform destroy
```

## License

This project is provided as-is for personal/lab use.
