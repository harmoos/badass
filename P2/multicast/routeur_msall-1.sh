#!/bin/sh
set -e

# Nettoyage
ip link del vxlan10 2>/dev/null || true
ip link del br0 2>/dev/null || true

# Underlay
ip link set eth0 up
ip addr flush dev eth0
ip addr add 10.0.0.1/24 dev eth0

# Interface locale
ip link set eth1 up

# Bridge
ip link add br0 type bridge
ip link set br0 up

# VXLAN multicast
# Tous les VTEP utilisent le même groupe 239.1.1.1
ip link add vxlan10 type vxlan \
    id 10 \
    local 10.0.0.1 \
    group 239.1.1.1 \
    dev eth0 \
    dstport 4789

ip link set vxlan10 up

# Bridge entre LAN local et VXLAN
ip link set eth1 master br0
ip link set vxlan10 master br0

echo "routeur_msall-1 multicast VXLAN configured"
