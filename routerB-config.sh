#!/bin/bash

# Este script configura interfaces VLAN en Router B y habilita el reenvío de paquetes

set -e

echo "Configurando interfaces VLAN para Router B..."

# Ruta del archivo de interfaces
INTERFACES_FILE="/etc/network/interfaces"

# Escribir configuración en /etc/network/interfaces
cat <<EOF | sudo tee $INTERFACES_FILE > /dev/null

auto enp1s0
iface enp1s0 inet manual

# Subred C - VLAN 10
auto enp1s0.10
iface enp1s0.10 inet static
    address 192.168.10.1
    netmask 255.255.255.128
    vlan-raw-device enp1s0

# Subred D - VLAN 20
auto enp1s0.20
iface enp1s0.20 inet static
    address 192.168.20.1
    netmask 255.255.255.0
    vlan-raw-device enp1s0

# Subred E - VLAN 30
auto enp1s0.30
iface enp1s0.30 inet static
    address 192.168.30.1
    netmask 255.255.254.0
    vlan-raw-device enp1s0
EOF

echo "Habilitando IP forwarding..."

# Activar IP forwarding inmediatamente
sudo sysctl -w net.ipv4.ip_forward=1

# Hacerlo permanente en /etc/sysctl.conf
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
  echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
fi

echo "Reiniciando red..."
sudo systemctl restart networking

echo "Configuración completada en Router B."
