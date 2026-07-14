#!/bin/bash
set -e

echo "Installing AirPulse systemd service..."

SERVICE_SOURCE="$HOME/airpulse/Service/airpulse-node.service"
SERVICE_TARGET="/etc/systemd/system/airpulse-node.service"

echo "Stopping AirPulse service if running..."
sudo systemctl stop airpulse-node.service || true

echo "Stopping any manually running AirPulse.Node..."
sudo pkill -f AirPulse.Node || true

echo "Unmasking airpulse-node.service if needed..."
sudo systemctl unmask airpulse-node.service || true

echo "Copying service file..."
sudo cp "$SERVICE_SOURCE" "$SERVICE_TARGET"

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Enabling AirPulse service..."
sudo systemctl enable airpulse-node.service

echo "Starting AirPulse service..."
sudo systemctl start airpulse-node.service

echo "AirPulse service status:"
sudo systemctl status airpulse-node.service --no-pager