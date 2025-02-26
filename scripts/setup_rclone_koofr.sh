#!/bin/bash

# Variables
MOUNT_DIR="/mnt/SmartFrame"
SERVICE_FILE="/etc/systemd/system/rclone-koofr.service"
FUSE_CONF="/etc/fuse.conf"

echo "Updating system and installing dependencies..."
sudo apt install -y rclone fuse

# Ensure FUSE allows 'allow_other'
if grep -q "^user_allow_other" $FUSE_CONF; then
    echo "'user_allow_other' is already set in $FUSE_CONF"
else
    echo "Enabling 'user_allow_other' in $FUSE_CONF..."
    sudo sed -i '/#user_allow_other/c\user_allow_other' $FUSE_CONF
fi

echo "Creating mount directory..."
sudo mkdir -p $MOUNT_DIR
sudo chown $(whoami):$(whoami) $MOUNT_DIR

echo "Copying rclone configuration (Make sure rclone.conf is backed up)..."
mkdir -p ~/.config/rclone
cp rclone.conf ~/.config/rclone/rclone.conf

echo "Creating systemd service..."
sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=Mount Koofr Cloud Storage using rclone
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/rclone mount Koofr:SmartFrame $MOUNT_DIR --config=/home/$(whoami)/.config/rclone/rclone.conf --allow-other --vfs-cache-mode writes
ExecStop=/bin/fusermount -u $MOUNT_DIR
Restart=always
User=$(whoami)
Group=$(whoami)

[Install]
WantedBy=default.target
EOF

echo "Reloading systemd and enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable rclone-koofr
sudo systemctl start rclone-koofr

echo "Setup complete! Please reboot for changes to take effect."

