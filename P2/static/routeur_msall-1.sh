#!/bin/sh
set -e

# Nettoyage si le script est relancé
ip link del vxlan10 2>/dev/null || true
ip link del br0 2>/dev/null || true

# Underlay : connexion IP entre les deux VTEP
ip link set eth0 up
ip addr flush dev eth0
ip addr add 10.0.0.1/24 dev eth0

# Interface locale vers host_msall-1
ip link set eth1 up

# Bridge L2
ip link add br0 type bridge
ip link set br0 up

# VXLAN statique
# VNI obligatoire : 10
# Le VTEP distant est explicitement 10.0.0.2
ip link add vxlan10 type vxlan \
    id 10 \
    local 10.0.0.1 \
    remote 10.0.0.2 \
    dev eth0 \
    dstport 4789

ip link set vxlan10 up

# Le bridge relie le LAN local au tunnel VXLAN
ip link set eth1 master br0
ip link set vxlan10 master br0

echo "routeur_msall-1 static VXLAN configured"
