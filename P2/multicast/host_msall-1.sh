#!/bin/sh
set -e

ip link set eth1 up
ip addr flush dev eth1
ip addr add 30.1.1.1/24 dev eth1

echo "host_msall-1 configured"
