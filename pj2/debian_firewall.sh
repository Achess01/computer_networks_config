#!/bin/bash

# ====== VARIABLES ======
WAN_IF="enp1s0"                 # Interfaz física hacia Ubuntu (ISPs)
LAN_IF="enx00e04c3603ba"        # Interfaz física hacia balanceador

# VLANs WAN (hacia ISPs simulados)
VLAN_ISP1_ID=70
VLAN_ISP2_ID=80
ISP1_NET="192.168.70.0/24"
ISP2_NET="192.168.80.0/24"
ISP1_IP="192.168.70.2/24"
ISP2_IP="192.168.80.2/24"
ISP1_GW="192.168.70.1"
ISP2_GW="192.168.80.1"
WAN1_VLAN_NAME="${WAN_IF}.${VLAN_ISP1_ID}"
WAN2_VLAN_NAME="${WAN_IF}.${VLAN_ISP2_ID}"

# VLANs LAN (hacia el balanceador)
VLAN_LAN1_ID=10
VLAN_LAN2_ID=20
LAN1_NET="10.10.10.0/24"
LAN2_NET="10.10.20.0/24"
LAN1_IP="10.10.10.1/24"
LAN2_IP="10.10.20.1/24"
LAN1_VLAN_NAME="${LAN_IF}.${VLAN_LAN1_ID}"
LAN2_VLAN_NAME="${LAN_IF}.${VLAN_LAN2_ID}"

# ====== FUNCIONES ======

cleanup() {
  echo "[+] Limpiando configuración..."
  iptables -t nat -F
  iptables -F FORWARD
  ip rule flush
  ip route flush cache
  ip route flush table 100
  ip route flush table 200
  ip link del $WAN1_VLAN_NAME 2>/dev/null
  ip link del $WAN2_VLAN_NAME 2>/dev/null
  ip link del $LAN1_VLAN_NAME 2>/dev/null
  ip link del $LAN2_VLAN_NAME 2>/dev/null
  echo "[+] Limpieza completa."
}

create_vlans() {
  echo "[+] Creando VLANs..."
  # VLANs WAN
  ip link add link $WAN_IF name $WAN1_VLAN_NAME type vlan id $VLAN_ISP1_ID
  ip link add link $WAN_IF name $WAN2_VLAN_NAME type vlan id $VLAN_ISP2_ID
  ip addr add $ISP1_IP dev $WAN1_VLAN_NAME
  ip addr add $ISP2_IP dev $WAN2_VLAN_NAME
  ip link set $WAN1_VLAN_NAME up
  ip link set $WAN2_VLAN_NAME up

  # VLANs LAN
  ip link add link $LAN_IF name $LAN1_VLAN_NAME type vlan id $VLAN_LAN1_ID
  ip link add link $LAN_IF name $LAN2_VLAN_NAME type vlan id $VLAN_LAN2_ID
  ip addr add $LAN1_IP dev $LAN1_VLAN_NAME
  ip addr add $LAN2_IP dev $LAN2_VLAN_NAME
  ip link set $LAN1_VLAN_NAME up
  ip link set $LAN2_VLAN_NAME up
}

# --- NUEVA FUNCIÓN ---
tune_kernel() {
  echo "[+] Ajustando parámetros del kernel..."
  # Habilitar reenvío de paquetes
  sysctl -w net.ipv4.ip_forward=1
  # Relajar el filtro de ruta inversa (CRUCIAL para enrutamiento multi-interfaz)
  sysctl -w net.ipv4.conf.all.rp_filter=2
  sysctl -w net.ipv4.conf.$WAN_IF.rp_filter=2
  sysctl -w net.ipv4.conf.$LAN_IF.rp_filter=2
}

# --- FUNCIÓN MEJORADA ---
setup_firewall_and_nat() {
  echo "[+] Configurando reglas de Firewall y NAT..."
  # Limpiar reglas previas
  iptables -t nat -F
  iptables -F FORWARD

  # Política por defecto: denegar todo el tráfico reenviado
  iptables -P FORWARD DROP

  # Reglas Stateful: Permitir el tráfico que nosotros iniciamos y el relacionado
  iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

  # Permitir el reenvío desde CUALQUIER LAN hacia CUALQUIER WAN
  iptables -A FORWARD -i $LAN1_VLAN_NAME -o $WAN1_VLAN_NAME -j ACCEPT
  iptables -A FORWARD -i $LAN1_VLAN_NAME -o $WAN2_VLAN_NAME -j ACCEPT
  iptables -A FORWARD -i $LAN2_VLAN_NAME -o $WAN1_VLAN_NAME -j ACCEPT
  iptables -A FORWARD -i $LAN2_VLAN_NAME -o $WAN2_VLAN_NAME -j ACCEPT

  # NAT (Enmascaramiento): Ocultar las IPs de la LAN detrás de la IP de la WAN por la que salen
  iptables -t nat -A POSTROUTING -o $WAN1_VLAN_NAME -j MASQUERADE
  iptables -t nat -A POSTROUTING -o $WAN2_VLAN_NAME -j MASQUERADE
}

setup_routes() {
  echo "[+] Configurando rutas y tablas..."
  # Asegurar que las tablas existen
  grep -q "100 isp1" /etc/iproute2/rt_tables || echo "100 isp1" >> /etc/iproute2/rt_tables
  grep -q "200 isp2" /etc/iproute2/rt_tables || echo "200 isp2" >> /etc/iproute2/rt_tables

  # Configurar rutas para cada tabla de proveedor
  ip route add $ISP1_NET dev $WAN1_VLAN_NAME table 100
  ip route add default via $ISP1_GW dev $WAN1_VLAN_NAME table 100

  ip route add $ISP2_NET dev $WAN2_VLAN_NAME table 200
  ip route add default via $ISP2_GW dev $WAN2_VLAN_NAME table 200

  # Reglas de enrutamiento: el tráfico que venga DE una red LAN, debe ser respondido por la misma ruta
  # Esto asegura que las conexiones no se rompan (enrutamiento simétrico)
  ip rule add from $LAN1_NET table 100
  ip rule add from $LAN2_NET table 200
  
  # Ruta por defecto principal para el tráfico originado por el propio firewall
  ip route add default via $ISP1_GW
}


# ====== MENÚ ======
case "$1" in
  start)
    cleanup
    create_vlans
    tune_kernel
    setup_firewall_and_nat
    setup_routes
    echo "[+] Firewall iniciado correctamente."
    ;;
  stop)
    cleanup
    ;;
  *)
    echo "Uso: $0 {start|stop}"
    ;;
esac