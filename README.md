# Configuración de Red con QEMU/KVM + VLANs + Router Debian

Este proyecto configura una red virtual con 3 subredes (VLANs) entre una máquina virtualizadora (Ubuntu), un router (Debian) y 3 máquinas virtuales (Debian).

## Estructura

- `virtualizadora-netplan.sh`: Configura bridges y VLANs en Ubuntu usando Netplan.
- `routerB-config.sh`: Configura las interfaces y VLANs en el router Debian. Activa el reenvío de paquetes en el router.
- `setup-vmC.sh`: Asigna IP estática a la VM1 (subred C / VLAN 10).
- `setup-vmD.sh`: Asigna IP estática a la VM2 (subred D / VLAN 20).
- `setup-vmE.sh`: Asigna IP estática a la VM3 (subred E / VLAN 30).
