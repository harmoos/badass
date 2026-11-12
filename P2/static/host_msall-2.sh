#!/bin/sh
set -e

# Host 2 du LAN étendu par VXLAN
ip link set eth1 up
ip addr flush dev eth1
ip addr add 30.1.1.2/24 dev eth1

echo "host_msall-2 configured"
