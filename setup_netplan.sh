#!/bin/bash

# Este script configura Netplan para usar VLANs y bridges en Ubuntu

set -e  # Detener el script si ocurre un error

echo "Creando configuración de red con Netplan..."

# Ruta del archivo de configuración
NETPLAN_CONFIG="/etc/netplan/01-network.yaml"

# Crear el contenido YAML
cat <<EOF | sudo tee $NETPLAN_CONFIG > /dev/null
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    eno1:
      dhcp4: no

  vlans:
    vlan10:
      id: 10
      link: eno1
    vlan20:
      id: 20
      link: eno1
    vlan30:
      id: 30
      link: eno1

  bridges:
    br10:
      interfaces: [vlan10]
      dhcp4: no
    br20:
      interfaces: [vlan20]
      dhcp4: no
    br30:
      interfaces: [vlan30]
      dhcp4: no
EOF

echo "Aplicando configuración de red..."
sudo netplan apply

echo "Configuración completada."
