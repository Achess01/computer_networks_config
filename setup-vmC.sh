#!/bin/bash

# Configura IP estática para VM1 en Subred C (VLAN 10)

set -e

cat <<EOF | sudo tee /etc/network/interfaces > /dev/null
auto enp1s0
iface enp1s0 inet static
    address 192.168.10.10
    netmask 255.255.255.128
    gateway 192.168.10.1
EOF

echo "Reiniciando red..."
sudo systemctl restart networking
echo "VM en Sub red C configurada con IP 192.168.10.10"
