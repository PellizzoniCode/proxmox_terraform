resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl",
    {
      control_plane = {
        index      = range(var.control_plane_nr)
        ip_address = [for i in range(var.control_plane_nr) : cidrhost(var.bridge_cidr_range, var.control_plane_network_range + i)]
        user       = [for i in range(var.control_plane_nr) : var.ciuser]
        vm_name    = proxmox_virtual_environment_vm.control_planes[*].name
      }
      worker = {
        index      = range(var.worker_nr)
        ip_address = [for i in range(var.worker_nr) : cidrhost(var.bridge_cidr_range, var.worker_network_range + i)]
        user       = [for i in range(var.worker_nr) : var.ciuser]
        vm_name    = proxmox_virtual_environment_vm.workers[*].name
      }
    }
  )
  filename        = "inventory.ini"
  file_permission = "0600"
}
