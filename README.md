# Configuración de Red con QEMU/KVM + VLANs + Router Debian

Este proyecto configura una red virtual con 3 subredes (VLANs) entre una máquina virtualizadora (Ubuntu), un router (Debian) y 3 máquinas virtuales (Debian).

## Estructura

- `virtualizadora-netplan.sh`: Configura bridges y VLANs en Ubuntu usando Netplan.
- `routerB-config.sh`: Configura las interfaces y VLANs en el router Debian. Activa el reenvío de paquetes en el router.
- `setup-vmC.sh`: Asigna IP estática a la VM1 (subred C / VLAN 10).
- `setup-vmD.sh`: Asigna IP estática a la VM2 (subred D / VLAN 20).
- `setup-vmE.sh`: Asigna IP estática a la VM3 (subred E / VLAN 30).

# Virtualizadora - PISO SECUNDARIO
- Agregar br10: A VM de la subred C
- Agregar br20: A VM de la subred D
- Agregar br30: A VM de la subred E

# Virtualizadora - PISO PRINCIPAL
## En virt-manager
1. Crear bridges internos (brA y brB)
Abre virt-manager
2. Editar → Detalles de la conexión
3. Pestaña Interfaces o Redes virtuales
4. Crear dos nuevas redes "solo anfitrión" o "aisladas":
    brA: para subred A (ej. 192.168.40.0/24)
    brB: para subred B (ej. 192.168.50.0/27)



## Para Router A
- Agregar 3 interfaces de red
- NIC 1: conectado a br60 (bridge externo que conecta con Router B)
- NIC 2: conectado a brA
- NIC 3: conectado a brB

## Para Cliente A
- Conectar a brA (usará NIC virtual conectada a esa red)

## Para Cliente B
- Conectar a brB

# Requisitos
- hostapd (Router B)

# Subredes
- 192.168.10.0 - Subred C
- 192.168.20.0 - Subred D
- 192.168.30.0 - Subred E
- 192.168.40.0 - Subred A
- 192.168.50.0 - Subred B
- 192.168.60.0 - Router A
- 192.168.70.0 - Wifi AP