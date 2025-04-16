#!/bin/bash
set -e

echo "Configurando Router A..."

# Asignar IPs estáticas a las tres interfaces
cat <<EOF | sudo tee /etc/network/interfaces > /dev/null
auto enp1s0
iface enp1s0 inet static
    address 192.168.60.2
    netmask 255.255.255.0
    gateway 192.168.60.1

# Subred A
auto enp7s0
iface enp7s0 inet static
    address 192.168.40.1
    netmask 255.255.255.0

# Subred B
auto enp8s0
iface enp8s0 inet static
    address 192.168.50.1
    netmask 255.255.255.224
EOF

# Activar reenvío de paquetes
sudo sysctl -w net.ipv4.ip_forward=1

# Hacerlo permanente
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
  echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
fi

sudo systemctl restart networking
echo "Configuración completada en Router A."