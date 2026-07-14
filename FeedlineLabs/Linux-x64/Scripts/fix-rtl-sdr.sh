#!/bin/bash
set -e

echo "Installing RTL-SDR kernel driver blacklist..."

printf 'blacklist dvb_usb_rtl28xxu\nblacklist rtl2832\nblacklist rtl2830\n' | sudo tee /etc/modprobe.d/blacklist-rtl-sdr.conf > /dev/null

echo "Verifying blacklist file..."
cat /etc/modprobe.d/blacklist-rtl-sdr.conf

echo "Installing RTL-SDR USB permission rule..."

printf 'SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", MODE:="0666"\n' | sudo tee /etc/udev/rules.d/20-rtlsdr.rules > /dev/null

echo "Verifying udev rule..."
cat /etc/udev/rules.d/20-rtlsdr.rules

echo "Reloading udev rules..."
sudo udevadm control --reload-rules

echo "RTL-SDR setup complete."
echo "Reboot before testing AirPulse.Node."