#!/bin/bash

set -e

# Ruta del archivo de configuración
NFTABLES_CONF="/etc/nftables.conf"

echo "Creando archivo de configuración $NFTABLES_CONF..."

sudo tee "$NFTABLES_CONF" > /dev/null << 'EOF'
#!/usr/sbin/nft -f

flush ruleset

table inet firewall {
  chain input {
    type filter hook input priority 0;
    policy drop;

    # Permitir loopback
    iif "lo" accept

    # Permitir conexiones establecidas
    ct state established,related accept

    # Permitir acceso SSH desde la subred B
    ip saddr 192.168.50.0/27 tcp dport 22 ct state new log prefix "ACCEPTED: SSH desde B" flags all level info accept
  }

  chain forward {
    type filter hook forward priority 0;
    policy drop;

    # Permitir conexiones ya establecidas
    ct state established,related accept

    # Bloquear nuevas conexiones hacia la subred B
    ip saddr 192.168.10.0/25 ip daddr 192.168.50.0/27 ct state new log prefix "REJECTED: C→B" flags all level warn drop
    ip saddr 192.168.20.0/24 ip daddr 192.168.50.0/27 ct state new log prefix "REJECTED: D→B" flags all level warn drop
    ip saddr 192.168.30.0/23 ip daddr 192.168.50.0/27 ct state new log prefix "REJECTED: E→B" flags all level warn drop

    # Bloquear conexiones de C hacia D
    ip saddr 192.168.10.0/25 ip daddr 192.168.20.0/24 ct state new log prefix "REJECTED: C→D" flags all level warn drop

    # Bloquear conexiones de E hacia D
    ip saddr 192.168.30.0/23 ip daddr 192.168.20.0/24 ct state new log prefix "REJECTED: E→D" flags all level warn drop

    # Bloquear nuevas conexiones hacia METABASE
    ip daddr 192.168.40.10 ct state new log prefix "REJECTED: acceso a METABASE" flags all level warn drop

    # Subred B → A, C, D, E
    ip saddr 192.168.50.0/27 ip daddr 192.168.40.0/24 ct state new log prefix "ACCEPTED: B→A" flags all level info accept
    ip saddr 192.168.50.0/27 ip daddr 192.168.10.0/25 ct state new log prefix "ACCEPTED: B→C" flags all level info accept
    ip saddr 192.168.50.0/27 ip daddr 192.168.20.0/24 ct state new log prefix "ACCEPTED: B→D" flags all level info accept
    ip saddr 192.168.50.0/27 ip daddr 192.168.30.0/23 ct state new log prefix "ACCEPTED: B→E" flags all level info accept

    # Subred C → E
    ip saddr 192.168.10.0/25 ip daddr 192.168.30.0/23 ct state new log prefix "ACCEPTED: C→E" flags all level info accept

    # Subred D → C
    ip saddr 192.168.20.0/24 ip daddr 192.168.10.0/25 ct state new log prefix "ACCEPTED: D→C" flags all level info accept

    # Subred E → C
    ip saddr 192.168.30.0/23 ip daddr 192.168.10.0/25 ct state new log prefix "ACCEPTED: E→C" flags all level info accept

    # Permitir Home page pública en subred A
    ip daddr 192.168.40.30 ct state new log prefix "ACCEPTED: acceso a HomePage A" flags all level info accept

    # Permitir conexiones de piso secundario a Home page de departamentos
    ip saddr 192.168.10.0/25 ip daddr 192.168.40.20 ct state new log prefix "ACCEPTED: C→DepA" flags all level info accept
    ip saddr 192.168.20.0/24 ip daddr 192.168.40.20 ct state new log prefix "ACCEPTED: D→DepA" flags all level info accept
    ip saddr 192.168.30.0/23 ip daddr 192.168.40.20 ct state new log prefix "ACCEPTED: E→DepA" flags all level info accept
  }

  chain output {
    type filter hook output priority 0;
    policy accept;
  }
}
EOF

echo "Habilitando y cargando nftables..."
sudo systemctl enable nftables
sudo systemctl restart nftables

echo "Verificando configuración activa..."
sudo nft list ruleset

echo "Configuración completada."
