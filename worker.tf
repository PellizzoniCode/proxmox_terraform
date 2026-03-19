resource "proxmox_virtual_environment_vm" "workers" {
  count     = var.worker_nr
  name      = format("%s-%d", var.worker_naming, count.index + 1)
  node_name = var.target_node
  vm_id     = var.worker_id_range + count.index + 1

  on_boot = true
  started = true # Explicitly start VM after creation so cloud-init runs

  clone {
    vm_id        = var.template_vmid
    full         = true
    datastore_id = "local-lvm"
  }

  agent {
    enabled = true
  }

  cpu {
    cores   = var.worker_cores
    sockets = var.worker_sockets
  }

  memory {
    dedicated = var.worker_memory
  }

  # FIX: Removed the disk block. When cloning, the scsi0 disk is already
  # present from the template. Declaring it again causes conflicts with
  # the bpg/proxmox provider that can break the boot disk configuration.

  network_device {
    bridge = var.bridge_network
    model  = "virtio"
    # FIX: Removed firewall = true. The Proxmox firewall default inbound
    # policy is DROP. With no rules defined to allow port 22, enabling
    # the firewall here blocks ALL inbound traffic including SSH.
  }

  initialization {
    datastore_id = "local-lvm"
    interface    = "ide2"

    user_account {
      username = var.ciuser
      keys     = [var.ssh_keys]
    }
    ip_config {
      ipv4 {
        address = "${cidrhost(var.bridge_cidr_range, var.worker_network_range + count.index)}/24"
        gateway = cidrhost(var.bridge_cidr_range, 1)
      }
    }
  }

  # Proxmox may report network info changes after cloud-init runs;
  # ignore those to prevent unnecessary plan diffs.
  lifecycle {
    ignore_changes = [network_device]
  }

  tags = ["workers"]
}
