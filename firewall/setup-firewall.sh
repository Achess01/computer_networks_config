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
    ip saddr 192.168.50.0/27 tcp dport 22 accept
  }

  chain forward {
    type filter hook forward priority 0;
    policy drop;

    # Permitir conexiones ya establecidas
    ct state established,related accept

    # Bloquear nuevas conexiones hacia la subred B
    ip saddr 192.168.10.0/24 ip daddr 192.168.50.0/27 ct state new drop
    ip saddr 192.168.20.0/24 ip daddr 192.168.50.0/27 ct state new drop
    ip saddr 192.168.30.0/24 ip daddr 192.168.50.0/27 ct state new drop

    # Bloquear nuevas conexiones hacia METABASE
    ip daddr 192.168.40.10 ct state new drop

    # Subred B → A, C, D, E
    ip saddr 192.168.50.0/27 ip daddr {192.168.40.0/24, 192.168.10.0/24, 192.168.20.0/24, 192.168.30.0/24} accept

    # Subred C → E
    ip saddr 192.168.10.0/24 ip daddr 192.168.30.0/24 accept

    # Subred D → C
    ip saddr 192.168.20.0/24 ip daddr 192.168.10.0/24 accept

    # Subred E → C
    ip saddr 192.168.30.0/24 ip daddr 192.168.10.0/24 accept

    # Permitir Home page pública en subred A
    ip daddr 192.168.40.10 accept

    # LOG conexiones aceptadas
    ip saddr 192.168.0.0/16 ip daddr 192.168.0.0/16 log prefix "ACCEPTED: " flags all level info accept

    # LOG conexiones rechazadas
    log prefix "REJECTED: " flags all level warn drop
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
