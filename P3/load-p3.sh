#!/bin/sh
set -e

PROJECT="a20c6fb5-6193-4fcf-9424-b710102144fe"

# Routeurs : loopbacks + FRR
for n in 1 2 3 4; do
    C="GNS3.msall-$n.$PROJECT"
    docker cp "/vagrant/P3/configs/msall-$n/frr.conf" "$C:/etc/frr/frr.conf"
    docker exec "$C" sh -c "touch /etc/frr/vtysh.conf && chown frr:frr /etc/frr/vtysh.conf"
    docker exec "$C" ip addr replace "1.1.1.$n/32" dev lo
    docker exec "$C" sh -c '
        pkill -9 watchfrr 2>/dev/null || true
        pkill -9 zebra 2>/dev/null || true
        pkill -9 bgpd 2>/dev/null || true
        pkill -9 ospfd 2>/dev/null || true
        pkill -9 isisd 2>/dev/null || true
        pkill -9 staticd 2>/dev/null || true
        rm -f /run/frr/*.pid
        /usr/lib/frr/frrinit.sh start
    '
    docker exec "$C" vtysh -f /etc/frr/frr.conf
done

# VXLAN msall-2
C="GNS3.msall-2.$PROJECT"
docker exec "$C" sh -c '
ip link set eth1 up
ip link show br0 >/dev/null 2>&1 || ip link add br0 type bridge
ip link set br0 up
ip link show vxlan10 >/dev/null 2>&1 || ip link add vxlan10 type vxlan id 10 local 1.1.1.2 dstport 4789 nolearning
ip link set vxlan10 up
ip link set eth1 master br0
ip link set vxlan10 master br0
'

# VXLAN msall-3 et msall-4
for n in 3 4; do
    C="GNS3.msall-$n.$PROJECT"
    docker exec "$C" sh -c "
    ip link set eth0 up
    ip link show br0 >/dev/null 2>&1 || ip link add br0 type bridge
    ip link set br0 up
    ip link show vxlan10 >/dev/null 2>&1 || ip link add vxlan10 type vxlan id 10 local 1.1.1.$n dstport 4789 nolearning
    ip link set vxlan10 up
    ip link set eth0 master br0
    ip link set vxlan10 master br0
    "
done

# Hosts
for n in 1 2 3; do
    C="GNS3.host-msall-$n.$PROJECT"
    docker exec "$C" ip addr replace "30.1.1.$n/24" dev eth0
done

echo "P3 configuration restored."

echo "Waiting for EVPN convergence..."
sleep 15
echo "P3 ready."
