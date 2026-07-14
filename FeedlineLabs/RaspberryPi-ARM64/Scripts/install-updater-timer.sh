#!/bin/bash
set -e

echo "Installing AirPulse updater timer..."

UPDATER_SERVICE="/etc/systemd/system/airpulse-updater.service"
UPDATER_TIMER="/etc/systemd/system/airpulse-updater.timer"

echo "Making AirPulse.Updater executable..."
chmod +x "$HOME/airpulse/AirPulse.Updater"

echo "Creating updater service..."
sudo tee "$UPDATER_SERVICE" > /dev/null <<'EOF'
[Unit]
Description=AirPulse Updater
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=airpulse-user
WorkingDirectory=/home/airpulse-user/airpulse
ExecStart=/home/airpulse-user/airpulse/AirPulse.Updater
EOF

echo "Creating updater timer..."
sudo tee "$UPDATER_TIMER" > /dev/null <<'EOF'
[Unit]
Description=Run AirPulse Updater every 10 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=10min
Unit=airpulse-updater.service

[Install]
WantedBy=timers.target
EOF

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Enabling updater timer..."
sudo systemctl enable airpulse-updater.timer

echo "Starting updater timer..."
sudo systemctl start airpulse-updater.timer

echo "Updater timer status:"
sudo systemctl status airpulse-updater.timer --no-pager

echo "Done."