#!/bin/bash
# Build a Debian 12 (Bookworm) Proxmox template with qemu-guest-agent pre-installed.
# Run this on the Proxmox host as root.
#
# Usage: ./create-debian12-template.sh [VMID] [STORAGE]
# Defaults: VMID=9000, STORAGE=local-lvm

set -euo pipefail

VMID="${1:-9000}"
STORAGE="${2:-local-lvm}"
VM_NAME="debian12-cloud-init"
IMG_NAME="debian-12-genericcloud-amd64.qcow2"
IMG_URL="https://cloud.debian.org/images/cloud/bookworm/latest/${IMG_NAME}"
WORK_DIR="/tmp/debian12-template"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# ── 1. Download image ────────────────────────────────────────────────────────
if [ -f "$IMG_NAME" ]; then
  echo "==> Image already downloaded, skipping."
else
  echo "==> Downloading Debian 12 cloud image..."
  wget -q --show-progress "$IMG_URL" -O "$IMG_NAME"
fi

# ── 2. Install qemu-guest-agent into the image via qemu-nbd + chroot ────────
echo "==> Installing qemu-guest-agent into image (qemu-nbd + chroot)..."

if ! command -v qemu-nbd &>/dev/null; then
  echo "    Installing qemu-utils..."
  apt-get install -y qemu-utils
fi

MOUNT_DIR="/mnt/debian12-tmp"
mkdir -p "$MOUNT_DIR"

# Load nbd kernel module
modprobe nbd max_part=8

nbd_cleanup() {
  echo "    Unmounting chroot..."
  # Restore resolv.conf: remove our copy and recreate original symlink or backup
  rm -f "$MOUNT_DIR/etc/resolv.conf"
  if [ -n "${RESOLV_SYMLINK_TARGET:-}" ]; then
    ln -sf "$RESOLV_SYMLINK_TARGET" "$MOUNT_DIR/etc/resolv.conf" 2>/dev/null || true
  elif [ -f "$MOUNT_DIR/etc/resolv.conf.bak" ]; then
    mv "$MOUNT_DIR/etc/resolv.conf.bak" "$MOUNT_DIR/etc/resolv.conf" 2>/dev/null || true
  fi
  umount "$MOUNT_DIR/dev/pts"  2>/dev/null || true
  umount "$MOUNT_DIR/dev"      2>/dev/null || true
  umount "$MOUNT_DIR/proc"     2>/dev/null || true
  umount "$MOUNT_DIR/sys"      2>/dev/null || true
  umount "$MOUNT_DIR"          2>/dev/null || true
  qemu-nbd --disconnect /dev/nbd0 2>/dev/null || true
}
trap nbd_cleanup EXIT

# Connect qcow2 as a block device
qemu-nbd --connect=/dev/nbd0 "$WORK_DIR/$IMG_NAME"

# Wait for partitions to appear (up to 10 s)
echo "    Waiting for partitions..."
for i in $(seq 1 10); do
  [ -b /dev/nbd0p1 ] && break
  sleep 1
done

partprobe /dev/nbd0 2>/dev/null || true
sleep 1

# Show partitions
echo "    Partitions found:"
lsblk /dev/nbd0
echo "    Partition types:"
blkid | grep nbd0 || true

# Find root ext4 partition (Debian 12 genericcloud uses ext4 for /)
ROOT_PART=$(blkid | grep 'nbd0p' | grep 'TYPE="ext4"' | cut -d: -f1 | head -1)

if [ -z "$ROOT_PART" ]; then
  echo "ERROR: Could not find root ext4 partition. blkid output:"
  blkid | grep nbd0 || echo "(none)"
  exit 1
fi

echo "    Root partition: $ROOT_PART"
mount "$ROOT_PART" "$MOUNT_DIR"
mount --bind /dev       "$MOUNT_DIR/dev"
mount --bind /dev/pts   "$MOUNT_DIR/dev/pts"
mount --bind /proc      "$MOUNT_DIR/proc"
mount --bind /sys       "$MOUNT_DIR/sys"

# Give the chroot DNS so apt can reach the internet
# Debian 12 uses a dangling symlink for resolv.conf (systemd-resolved target
# doesn't exist without /run mounted), so save the symlink target and replace it.
RESOLV_SYMLINK_TARGET=""
if [ -L "$MOUNT_DIR/etc/resolv.conf" ]; then
  RESOLV_SYMLINK_TARGET=$(readlink "$MOUNT_DIR/etc/resolv.conf")
elif [ -f "$MOUNT_DIR/etc/resolv.conf" ]; then
  cp "$MOUNT_DIR/etc/resolv.conf" "$MOUNT_DIR/etc/resolv.conf.bak"
fi
rm -f "$MOUNT_DIR/etc/resolv.conf"
cp /etc/resolv.conf "$MOUNT_DIR/etc/resolv.conf"

echo "    Running apt to install qemu-guest-agent..."
DEBIAN_FRONTEND=noninteractive chroot "$MOUNT_DIR" apt-get update -y
DEBIAN_FRONTEND=noninteractive chroot "$MOUNT_DIR" apt-get install -y qemu-guest-agent

# Enable the service
echo "    Enabling qemu-guest-agent service..."
systemctl --root="$MOUNT_DIR" enable qemu-guest-agent

nbd_cleanup
trap - EXIT

echo "==> qemu-guest-agent installed."

# ── 3. Destroy existing template/VM with same VMID if present ───────────────
if qm status "$VMID" &>/dev/null; then
  echo "==> Destroying existing VM/template $VMID..."
  qm stop "$VMID" --skiplock 1 2>/dev/null || true
  qm destroy "$VMID" --purge 1
fi

# ── 4. Create the VM ─────────────────────────────────────────────────────────
echo "==> Creating VM $VMID ($VM_NAME)..."
qm create "$VMID" \
  --name "$VM_NAME" \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --serial0 socket \
  --vga serial0 \
  --agent enabled=1 \
  --ostype l26

# ── 5. Import disk ───────────────────────────────────────────────────────────
echo "==> Importing disk into $STORAGE..."
qm importdisk "$VMID" "$IMG_NAME" "$STORAGE"

# ── 6. Attach disk and cloud-init drive ─────────────────────────────────────
DISK_REF="${STORAGE}:vm-${VMID}-disk-0"
echo "==> Attaching disk $DISK_REF..."
qm set "$VMID" \
  --scsihw virtio-scsi-pci \
  --scsi0 "${DISK_REF},discard=on" \
  --ide2 "${STORAGE}:cloudinit" \
  --boot c \
  --bootdisk scsi0 \
  --citype nocloud

# ── 7. Convert to template ───────────────────────────────────────────────────
echo "==> Converting VM $VMID to template..."
qm template "$VMID"

echo ""
echo "Done! Template '$VM_NAME' created with VMID $VMID."
echo "Make sure terraform.tfvars has: template_vmid = $VMID"
echo ""
echo "Next steps:"
echo "  terraform destroy -var-file terraform.tfvars -auto-approve"
echo "  terraform apply   -var-file terraform.tfvars -auto-approve"
