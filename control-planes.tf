resource "proxmox_virtual_environment_vm" "control_planes" {
  count     = var.control_plane_nr
  name      = format("%s-%d", var.control_plane_naming, count.index + 1)
  node_name = var.target_node
  vm_id     = var.control_plane_id_range + count.index + 1

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
    cores   = var.control_plane_cores
    sockets = var.control_plane_sockets
  }

  memory {
    dedicated = var.control_plane_memory
  }

  # FIX: When cloning, do NOT declare a disk block for scsi0.
  # The clone already has the disk attached. Declaring it here causes
  # the provider to conflict with the cloned disk, potentially breaking
  # the boot configuration. Disk resizing should be done via the clone
  # itself or a separate null_resource/provisioner if needed.

  network_device {
    bridge = var.bridge_network
    model  = "virtio"
    # firewall is omitted (defaults to false) -- no Proxmox firewall on this NIC
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
        address = "${cidrhost(var.bridge_cidr_range, var.master_network_range + count.index)}/24"
        gateway = cidrhost(var.bridge_cidr_range, 1)
      }
    }
  }

  # Proxmox may report network info changes after cloud-init runs;
  # ignore those to prevent unnecessary plan diffs.
  lifecycle {
    ignore_changes = [network_device]
  }

  tags = ["masters"]
}
