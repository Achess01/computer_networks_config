#!/bin/bash
set -e

echo "Configurando VLAN 60 y el bridge br60..."
# Escribir nueva configuración
cat <<EOF | sudo tee /etc/netplan/01-network.yaml > /dev/null
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    eno1:
      dhcp4: no

  vlans:
    vlan60:
      id: 60
      link: eno1

  bridges:
    br60:
      interfaces: [vlan60]
      dhcp4: no
EOF

echo "Aplicando configuración de red..."
sudo netplan apply
