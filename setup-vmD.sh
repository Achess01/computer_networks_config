#!/bin/bash

# Configura IP estática para VM2 en Subred D (VLAN 20)

set -e

cat <<EOF | sudo tee /etc/network/interfaces > /dev/null
auto enp1s0
iface enp1s0 inet static
    address 192.168.20.10
    netmask 255.255.255.0
    gateway 192.168.20.1
EOF

echo "Reiniciando red..."
sudo systemctl restart networking
echo "VM en sub red D configurada con IP 192.168.20.10"
