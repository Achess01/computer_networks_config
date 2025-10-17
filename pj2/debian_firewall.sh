#!/bin/bash
# debian_firewall_static.sh
# Configura las VLANs estáticas del firewall hacia los 2 ISPs simulados

### CONFIGURACIÓN ###
IFACE="eth0"      # interfaz conectada al Ubuntu
VLAN1_ID=10
VLAN2_ID=20
IP_ISP1="192.168.10.2/24"
IP_ISP2="192.168.20.2/24"
GW_ISP1="192.168.10.1"
GW_ISP2="192.168.20.1"

### FUNCIONES ###
setup_vlans() {
  echo "[+] Creando VLANs..."
  ip link add link $IFACE name ${IFACE}.${VLAN1_ID} type vlan id $VLAN1_ID
  ip link add link $IFACE name ${IFACE}.${VLAN2_ID} type vlan id $VLAN2_ID

  ip addr add $IP_ISP1 dev ${IFACE}.${VLAN1_ID}
  ip addr add $IP_ISP2 dev ${IFACE}.${VLAN2_ID}

  ip link set ${IFACE}.${VLAN1_ID} up
  ip link set ${IFACE}.${VLAN2_ID} up
}

test_connectivity() {
  echo "[+] Probando conectividad con gateways..."
  ping -c 2 $GW_ISP1
  ping -c 2 $GW_ISP2
}

cleanup() {
  echo "[+] Limpiando configuración..."
  ip link del ${IFACE}.${VLAN1_ID} 2>/dev/null
  ip link del ${IFACE}.${VLAN2_ID} 2>/dev/null
}

### MENÚ ###
case "$1" in
  start)
    setup_vlans
    test_connectivity
    ;;
  stop)
    cleanup
    ;;
  *)
    echo "Uso: $0 {start|stop}"
    ;;
esac
