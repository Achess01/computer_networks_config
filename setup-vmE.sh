#!/bin/bash

# Configura IP estática para VM3 en Subred E (VLAN 30)

set -e

cat <<EOF | sudo tee /etc/network/interfaces > /dev/null
auto enp1s0
iface enp1s0 inet static
    address 192.168.30.10
    netmask 255.255.254.0
    gateway 192.168.30.1
EOF

echo "Reiniciando red..."
sudo systemctl restart networking
echo "VM3 configurada con IP 192.168.30.10"
