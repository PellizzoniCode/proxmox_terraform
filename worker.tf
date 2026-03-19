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

  disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    interface    = "scsi0"
    size         = var.worker_disksize
  }

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
