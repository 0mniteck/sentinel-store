#!/bin/bash
#rough draft

timeout 1h ffmpeg -f v4l2 -i /dev/video4 -c:v libx264 -crf 2 -display_hflip output.mp4; exit 0

# Set the storage pool directory
POOL_DIR="/path/to/storage/pool"

# Set the LUKS image file name
IMAGE_FILE="storage-pool-$(date +'%Y-%m-%d').img"

# Set the LUKS image file size (in GB)
IMAGE_SIZE=10

# Set the LUKS image file path
IMAGE_PATH="$POOL_DIR/$IMAGE_FILE"

# Create the LUKS image file
dd if=/dev/zero of="$IMAGE_PATH" bs=1G count=$IMAGE_SIZE

# Create the LUKS container
cryptsetup luksFormat "$IMAGE_PATH"

# Open the LUKS container
cryptsetup luksOpen "$IMAGE_PATH" storage-pool

# Create a filesystem on the LUKS container
mkfs.ext4 /dev/mapper/storage-pool

# Mount the LUKS container
mkdir -p "$POOL_DIR/mount"
mount /dev/mapper/storage-pool "$POOL_DIR/mount"

# Add the LUKS container to /etc/crypttab
echo "storage-pool $IMAGE_PATH none luks" >> /etc/crypttab

# Add the LUKS container to /etc/fstab
echo "/dev/mapper/storage-pool $POOL_DIR/mount ext4 defaults 0 0" >> /etc/fstab

# Reload systemd-cryptsetup
systemctl daemon-reload
systemctl restart systemd-cryptsetup@storage-pool.service
