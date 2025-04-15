#!/bin/bash
set -e

# Variables
WIFI_INTERFACE="wlp2s0"
SSID="Redes-AP"
PASSPHRASE="password123"
STATIC_IP="192.168.50.1"
NETMASK="255.255.255.0"

echo "==> Deteniendo hostapd por si está corriendo..."
sudo systemctl stop hostapd

echo "==> Configurando IP estática en la interfaz Wi-Fi..."
cat <<EOF | sudo tee -a /etc/network/interfaces > /dev/null

# Wi-Fi AP estático
auto $WIFI_INTERFACE
iface $WIFI_INTERFACE inet static
    address $STATIC_IP
    netmask $NETMASK
EOF

echo "==> Configurando hostapd..."
sudo mkdir -p /etc/hostapd

cat <<EOF | sudo tee /etc/hostapd/hostapd.conf > /dev/null
interface=$WIFI_INTERFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSPHRASE
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

echo "==> Apuntando hostapd al archivo de configuración..."
sudo sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

echo "==> Iniciando hostapd..."
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl restart hostapd

echo "Punto de acceso creado con IP estática en $STATIC_IP"
echo "Recuerda configurar manualmente la IP en los dispositivos clientes (por ejemplo, 192.168.50.10, gateway 192.168.50.1)"
