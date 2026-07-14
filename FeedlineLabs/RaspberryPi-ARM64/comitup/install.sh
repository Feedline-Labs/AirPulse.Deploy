sudo mkdir -p /Comitup && sudo chown airpulse-user:airpulse-user /Comitup && cd /Comitup

sudo apt update

apt-cache policy comitup

sudo apt install -y comitup

sudo sed -i 's/^# ap_name: comitup-<nnn>$/ap_name: AirPulse-Setup-<nnn>/' /etc/comitup.conf

sudo systemctl restart comitup; sleep 2; sudo comitup -i

-- AFTER Testing

WIFI_UUID=$(nmcli -t -f UUID,TYPE connection show --active | awk -F: '$2=="802-11-wireless"{print $1; exit}'); echo "$WIFI_UUID"; sudo nmcli connection delete uuid "$WIFI_UUID"

