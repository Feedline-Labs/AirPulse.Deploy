#!/bin/bash
#
# AirPulse - RTL-SDR host setup (Raspberry Pi OS / Debian)
#
#   1. Ensures the libusb runtime library is present.
#   2. Blacklists the kernel DVB-T drivers that can claim the dongle.
#   3. Installs USB permission rules for common RTL2832U/RTL2838 devices.
#   4. Applies the changes immediately when possible.
#
set -e

BLACKLIST_FILE="/etc/modprobe.d/blacklist-rtl-sdr.conf"
UDEV_RULE_FILE="/etc/udev/rules.d/20-rtlsdr.rules"
REBOOT_REQUIRED=0

echo "=============================================="
echo " AirPulse RTL-SDR setup"
echo "=============================================="

# ---------------------------------------------------------------------------
# 1. libusb runtime
#
# AirPulse loads its bundled librtlsdr-v4.so by absolute path, but that
# library's dependency on libusb is resolved through the normal Linux linker.
# A missing libusb shows up as a silent load failure that looks like
# "no dongle found".
#
# apt-get update is intentionally skipped. If libusb is already installed,
# this step needs no network access. If it is missing, the configured package
# sources must be reachable.
# ---------------------------------------------------------------------------
echo
echo "[1/4] Checking for libusb-1.0..."

if ldconfig -p 2>/dev/null | grep -F "libusb-1.0.so.0" > /dev/null; then
    echo "  [ok]   libusb-1.0 is already installed"
else
    echo "  [info] libusb-1.0 is missing; installing it..."
    sudo apt-get install -y --no-install-recommends libusb-1.0-0 || true
    sudo ldconfig || true
fi

if ! ldconfig -p 2>/dev/null | grep -F "libusb-1.0.so.0" > /dev/null; then
    echo "  [FAIL] libusb-1.0 could not be found after installation." >&2
    echo "         librtlsdr cannot load without it. Check apt sources and retry." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. Kernel driver blacklist
#
# If a DVB-T kernel driver owns the dongle, librtlsdr generally reports
# LIBUSB_ERROR_BUSY (-6). Missing USB permissions generally surface as
# LIBUSB_ERROR_ACCESS (-3).
#
# The generic dvb_usb_v2 framework is intentionally NOT blacklisted. It is
# shared by many unrelated DVB devices, and blacklisting dvb_usb_rtl28xxu is
# sufficient because that is the module that binds the dongle.
# ---------------------------------------------------------------------------
echo
echo "[2/4] Installing RTL-SDR kernel driver blacklist..."

sudo tee "$BLACKLIST_FILE" > /dev/null <<'EOF_BLACKLIST'
blacklist dvb_usb_rtl28xxu
blacklist rtl2832
blacklist rtl2830
EOF_BLACKLIST

echo "Verifying blacklist file..."
cat "$BLACKLIST_FILE"

# ---------------------------------------------------------------------------
# 3. USB permissions
#
# 2838 = RTL2838UHIDIR (RTL-SDR Blog V3/V4 and many generic dongles)
# 2832 = RTL2832U reference-design devices
#
# SUBSYSTEMS and ATTRS match the USB device in the udev parent chain and
# follow the upstream rtl-sdr.rules convention.
#
# If you ship a dongle reporting a different ID, add it here. Otherwise the
# blacklist may free the device while USB permissions still deny access.
# ---------------------------------------------------------------------------
echo
echo "[3/4] Installing RTL-SDR USB permission rules..."

sudo tee "$UDEV_RULE_FILE" > /dev/null <<'EOF_UDEV'
SUBSYSTEMS=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", MODE:="0666"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2832", MODE:="0666"
EOF_UDEV

echo "Verifying udev rules..."
cat "$UDEV_RULE_FILE"

# ---------------------------------------------------------------------------
# 4. Apply now
#
# Reload the rules, release the RTL-specific DVB driver if it is already
# loaded, then replay an add event only for matching Realtek USB devices
# rather than every device on the system.
# ---------------------------------------------------------------------------
echo
echo "[4/4] Applying changes to the running system..."

sudo udevadm control --reload-rules

if lsmod | awk '{print $1}' | grep -Fx "dvb_usb_rtl28xxu" > /dev/null; then
    echo "  [info] Releasing loaded dvb_usb_rtl28xxu driver..."

    if sudo modprobe -r dvb_usb_rtl28xxu; then
        echo "  [ok]   DVB-T kernel driver unloaded"
    else
        echo "  [WARN] Driver could not be unloaded; a reboot is required"
        REBOOT_REQUIRED=1
    fi
else
    echo "  [ok]   DVB-T kernel driver was not loaded"
fi

sudo udevadm trigger \
    --action=add \
    --subsystem-match=usb \
    --attr-match=idVendor=0bda \
    --attr-match=idProduct=2838

sudo udevadm trigger \
    --action=add \
    --subsystem-match=usb \
    --attr-match=idVendor=0bda \
    --attr-match=idProduct=2832

sudo udevadm settle

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------
echo
echo "=============================================="
echo " Verification"
echo "=============================================="

echo "  [ok]   libusb-1.0 is present"

if lsmod | awk '{print $1}' | grep -Fx "dvb_usb_rtl28xxu" > /dev/null; then
    echo "  [WARN] dvb_usb_rtl28xxu is still loaded"
    REBOOT_REQUIRED=1
else
    echo "  [ok]   DVB-T kernel driver is not loaded"
fi

if command -v lsusb > /dev/null 2>&1; then
    RTL_DEVICES="$(lsusb | grep -Ei '0bda:(2832|2838)' || true)"

    if [ -n "$RTL_DEVICES" ]; then
        echo "  [ok]   RTL-SDR dongle detected:"
        printf '%s\n' "$RTL_DEVICES" | sed 's/^/         /'
    else
        echo "  [info] No RTL-SDR dongle is currently connected"
    fi
else
    echo "  [info] lsusb is not installed; skipping device detection"
fi

echo

if [ "$REBOOT_REQUIRED" -eq 1 ]; then
    echo "RTL-SDR setup complete, but a reboot is required."
else
    echo "RTL-SDR setup complete. No reboot is required."
fi
