#!/usr/bin/env bash
# AirPulse.Node Raspberry Pi Installation Script
# Written by Scott N1OF
# Released under MIT License

set -euo pipefail

REPO="Feedline-Labs/AirPulse-Releases"
API="https://api.github.com/repos/$REPO/releases/latest"

INSTALL_RTLSDR=false
SCRIPT_DIR="$(pwd)"

cleanup() {
    if [[ -n "${ZIP_FILE:-}" && -f "$ZIP_FILE" ]]; then
        rm -f "$ZIP_FILE"
    fi
}

trap cleanup EXIT

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1"
        return 1
    fi
}

install_unzip() {
    if command -v unzip >/dev/null 2>&1; then
        echo "unzip is already installed."
        return
    fi

    echo "Installing unzip..."
    sudo apt update
    sudo apt install -y unzip
}

update_system() {
    read -rp "Would you like to update and upgrade your system first? (y/N): " UPDATE_SYSTEM

    if [[ "$UPDATE_SYSTEM" =~ ^[Yy]$ ]]; then
        echo
        echo "Updating package lists..."
        sudo apt update

        echo "Upgrading packages..."
        sudo apt upgrade -y
    else
        echo "Skipping system update."
    fi
}

install_rtlsdr() {
    read -rp "Would you like to install RTL-SDR support? This prevents libusb errors caused by default Linux drivers (y/N): " INSTALL

    if [[ "$INSTALL" =~ ^[Yy]$ ]]; then
        echo
        echo "Installing RTL-SDR support..."

        sudo apt update
        sudo apt install -y rtl-sdr

        sudo tee /etc/modprobe.d/airpulse-rtl-sdr-blacklist.conf >/dev/null <<'EOF'
blacklist dvb_usb_rtl28xxu
blacklist dvb_usb_v2
blacklist dvb_core
blacklist rtl2832
blacklist rtl2830
EOF

        INSTALL_RTLSDR=true

        echo "RTL-SDR support installed."
    else
        echo "Skipping RTL-SDR support."
    fi
}

install_service() {
    read -rp "Install AirPulse as a system service? (y/N): " INSTALL_SERVICE

    if [[ "$INSTALL_SERVICE" =~ ^[Yy]$ ]]; then

        if [[ ! -f "scripts/airpulse-node.service" ]]; then
            echo "Unable to find service file."
            echo "Skipping system service installation."
            return
        fi

        if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
            SERVICE_USER="$SUDO_USER"
        else
            SERVICE_USER="$(whoami)"
        fi

        INSTALL_PATH="$(pwd)"

        echo "Configuring service to run as user: $SERVICE_USER"
        echo "Configuring service working directory: $INSTALL_PATH"

        SERVICE_FILE_TMP=$(mktemp)

        # - Strip a leading UTF-8 BOM (some editors save unit files with one;
        #   older systemd versions fail to parse "[Unit]" if it's preceded by
        #   BOM bytes).
        # - Swap the packaged "airpulse" account for whoever is actually
        #   running this install.
        # - Point WorkingDirectory/ExecStart at wherever this release was
        #   actually extracted to, rather than the hardcoded
        #   /home/airpulse/airpulse-node, which only exists if you happen to
        #   be user "airpulse" and ran the installer from exactly that path.
        # - Fix "multi-user.targets" -> "multi-user.target" (the trailing "s"
        #   is a typo; with it, `systemctl enable` won't error, but the
        #   service silently won't be wired up to start on boot).
        sed -e '1s/^\xef\xbb\xbf//' \
            -e "s/^User=airpulse$/User=${SERVICE_USER}/" \
            -e "s#/home/airpulse/airpulse-node#${INSTALL_PATH}#g" \
            -e 's/^WantedBy=multi-user.targets$/WantedBy=multi-user.target/' \
            scripts/airpulse-node.service > "$SERVICE_FILE_TMP"

        echo "Installing system service..."

        sudo cp "$SERVICE_FILE_TMP" /etc/systemd/system/airpulse-node.service
        rm -f "$SERVICE_FILE_TMP"

        sudo systemctl daemon-reload
        sudo systemctl enable airpulse-node.service
        sudo systemctl start airpulse-node.service

        echo "AirPulse service installed and started."

    else
        echo
        echo "AirPulse will be run manually."
        echo
        echo "Run:"
        echo "./AirPulse.Node --urls http://0.0.0.0:5050"
    fi
}

reboot_prompt() {
    if [[ "$INSTALL_RTLSDR" == true ]]; then
        echo
        echo "A reboot is recommended to load the RTL-SDR driver changes."
    fi

    read -rp "Would you like to reboot now? (y/N): " REBOOT

    if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
        echo "Rebooting..."
        sudo reboot
    else
        echo "Please reboot your Raspberry Pi when convenient."
    fi
}


echo "Welcome to the AirPulse Install Script!"
echo "Detecting architecture..."

ARCH=$(uname -m)

case "$ARCH" in
    aarch64|arm64)
        FILE_PATTERN='AirPulse\.Node\.RaspberryPi\.ARM64\..*\.zip'
        ;;
    *)
        echo
        echo "This script is only for Raspberry Pi ARM64 systems."
        exit 1
        ;;
esac

echo "Compatible Raspberry Pi detected."
echo

require_command wget || {
    echo "wget is required. Install it with:"
    echo "sudo apt install wget"
    exit 1
}

require_command grep || exit 1
require_command cut || exit 1

update_system

install_unzip

echo
echo "Finding latest AirPulse Raspberry Pi ARM64 release..."

# NOTE: grep -m1 stops each grep after its first match so nothing downstream
# closes the pipe early. That avoids SIGPIPE hitting wget/grep further up the
# pipeline, which combined with `pipefail` could otherwise make this whole
# assignment look like a failure (and kill the script via `set -e`) even
# though the URL was found successfully.
DOWNLOAD_URL=$(wget -qO- "$API" \
    | grep -m1 -E "browser_download_url.*${FILE_PATTERN}" \
    | cut -d '"' -f4)

if [[ -z "$DOWNLOAD_URL" ]]; then
    echo
    echo "Unable to locate the latest Raspberry Pi ARM64 release."
    exit 1
fi

ZIP_FILE=$(basename "$DOWNLOAD_URL")
INSTALL_DIR="${ZIP_FILE%.zip}"

echo
echo "Downloading $ZIP_FILE..."

wget -O "$ZIP_FILE" "$DOWNLOAD_URL"

echo
echo "Extracting files..."

mkdir -p "$INSTALL_DIR"
unzip -q "$ZIP_FILE" -d "$INSTALL_DIR"

cd "$INSTALL_DIR"

chmod +x AirPulse.Node

install_rtlsdr

install_service

echo
echo "AirPulse installation complete!"

reboot_prompt
