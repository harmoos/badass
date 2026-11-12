# BADASS - Part 2

## Overview

This part of the BADASS project introduces VXLAN.

The goal is to build a Layer 2 network over an IP network using VXLAN, first in static mode and then in multicast mode.

The topology is built in GNS3 using:

- 2 host containers
- 2 router containers
- 1 Ethernet switch

The VXLAN VNI used in this project is:

```text
10
```

The bridge used on the routers is:

```text
br0
```

The VXLAN interface is:

```text
vxlan10
```

The VXLAN UDP destination port is:

```text
4789
```

---

## Topology

```text
host-msall-1
     |
     |
   eth1
router-msall-1
   eth0
     |
     |
 Switch-msall
     |
     |
   eth0
router-msall-2
   eth1
     |
     |
host-msall-2
```

More precisely:

```text
host-msall-1 eth1
        |
        |
      eth1
router-msall-1
      eth0
        |
        |
   Switch-msall
        |
        |
      eth0
router-msall-2
      eth1
        |
        |
host-msall-2 eth1
```

The two routers act as VXLAN Tunnel End Points, also called VTEPs.

---

# Network addressing

## Underlay network

The underlay is the IP network used to transport VXLAN packets between the two VTEPs.

```text
router-msall-1 eth0 : 10.0.0.1/24
router-msall-2 eth0 : 10.0.0.2/24
```

The two routers must be able to communicate directly through the Ethernet switch.

Example test from `router-msall-1`:

```bash
ping -c 3 10.0.0.2
```

---

## Overlay network

The overlay is the logical Layer 2 network transported through VXLAN.

```text
host-msall-1 eth1 : 30.1.1.1/24
host-msall-2 eth1 : 30.1.1.2/24
```

The two hosts behave as if they were connected to the same Ethernet LAN even though the traffic passes through the VXLAN tunnel.

Example test from `host-msall-1`:

```bash
ping -c 3 30.1.1.2
```

---

# VXLAN

VXLAN means:

```text
Virtual eXtensible LAN
```

VXLAN allows Ethernet frames to be transported over an IP network.

A Layer 2 Ethernet frame is encapsulated inside:

```text
Outer Ethernet
Outer IP
UDP
VXLAN
Inner Ethernet
Inner IP
ICMP / other payload
```

In this project:

```text
VNI = 10
UDP port = 4789
```

The VNI identifies the VXLAN network.

---

# VLAN vs VXLAN

A VLAN extends a Layer 2 network using VLAN tagging.

A VXLAN extends a Layer 2 network over a Layer 3 IP network.

Main differences:

```text
VLAN
- Layer 2 technology
- VLAN ID uses 12 bits
- around 4094 usable VLANs
- usually limited to the Ethernet infrastructure

VXLAN
- Layer 2 overlay transported over Layer 3
- VNI uses 24 bits
- supports many more logical networks
- uses VTEPs
- transported using UDP/IP
```

---

# Switch

A switch is a Layer 2 device.

It learns MAC addresses and associates them with ports.

When it receives an Ethernet frame, it uses its MAC address table to decide which port should receive the frame.

In this topology, the Ethernet switch connects the two router underlay interfaces.

```text
router-msall-1 eth0
        |
     switch
        |
router-msall-2 eth0
```

---

# Bridge

A Linux bridge behaves like a software switch.

In this project, each router contains a bridge called:

```text
br0
```

The bridge connects:

```text
eth1
vxlan10
```

Conceptually:

```text
host
 |
eth1
 |
br0
 |
vxlan10
 |
VXLAN tunnel
```

The bridge forwards Ethernet frames between the local host network and the VXLAN tunnel.

---

# Broadcast and multicast

## Broadcast

Broadcast traffic is sent to every device in the same Layer 2 broadcast domain.

Example:

```text
ARP request
```

When a host wants to discover the MAC address associated with an IP address, it can send a broadcast ARP request.

## Multicast

Multicast traffic is sent to a specific group of receivers.

Devices that are members of the multicast group receive the traffic.

In the multicast version of this project, the VXLAN group is:

```text
239.1.1.1
```

---

# VTEP

VTEP means:

```text
VXLAN Tunnel End Point
```

The VTEP is the endpoint of a VXLAN tunnel.

In this topology:

```text
router-msall-1 = VTEP 1
router-msall-2 = VTEP 2
```

A VTEP receives a normal Ethernet frame, encapsulates it inside VXLAN/UDP/IP, sends it through the underlay network, and the remote VTEP decapsulates it.

Example:

```text
host-msall-1
30.1.1.1
    |
    v
router-msall-1
10.0.0.1
    |
    | VXLAN / UDP / IP
    |
router-msall-2
10.0.0.2
    |
    v
host-msall-2
30.1.1.2
```

---

# Part 2 - Static VXLAN

In static mode, each VTEP explicitly knows the IP address of the remote VTEP.

## Router 1

Underlay IP:

```text
10.0.0.1/24
```

Remote VTEP:

```text
10.0.0.2
```

VXLAN configuration:

```bash
ip link add vxlan10 type vxlan \
    id 10 \
    local 10.0.0.1 \
    remote 10.0.0.2 \
    dev eth0 \
    dstport 4789
```

## Router 2

Underlay IP:

```text
10.0.0.2/24
```

Remote VTEP:

```text
10.0.0.1
```

VXLAN configuration:

```bash
ip link add vxlan10 type vxlan \
    id 10 \
    local 10.0.0.2 \
    remote 10.0.0.1 \
    dev eth0 \
    dstport 4789
```

## Bridge configuration

On both routers:

```bash
ip link add br0 type bridge
ip link set br0 up

ip link set eth1 master br0
ip link set vxlan10 master br0

ip link set eth1 up
ip link set vxlan10 up
```

The local interface and the VXLAN interface are therefore part of the same Layer 2 bridge.

## Static configuration files

The static configuration files are located in:

```text
P2/static/
```

Files:

```text
P2/static/host_msall-1.sh
P2/static/host_msall-2.sh
P2/static/routeur_msall-1.sh
P2/static/routeur_msall-2.sh
```

---

# Part 2 - Multicast VXLAN

The multicast topology is the same.

The difference is that the remote VTEP address is no longer configured explicitly.

Instead, both VTEPs join the same multicast group.

The multicast group used is:

```text
239.1.1.1
```

## Router 1

```bash
ip link add vxlan10 type vxlan \
    id 10 \
    local 10.0.0.1 \
    group 239.1.1.1 \
    dev eth0 \
    dstport 4789
```

## Router 2

```bash
ip link add vxlan10 type vxlan \
    id 10 \
    local 10.0.0.2 \
    group 239.1.1.1 \
    dev eth0 \
    dstport 4789
```

## Multicast configuration files

The multicast configuration files are located in:

```text
P2/multicast/
```

Files:

```text
P2/multicast/host_msall-1.sh
P2/multicast/host_msall-2.sh
P2/multicast/routeur_msall-1.sh
P2/multicast/routeur_msall-2.sh
```

---

# Static vs multicast

## Static mode

Each VTEP must explicitly know its remote VTEP.

Example:

```text
router-msall-1
remote 10.0.0.2

router-msall-2
remote 10.0.0.1
```

This is easy to understand and configure when there are only a few VTEPs.

However, with many VTEPs, every endpoint must be configured manually.

## Multicast mode

Each VTEP joins a common multicast group:

```text
239.1.1.1
```

Example:

```text
router-msall-1 ----\
                    \
                     -> 239.1.1.1
                    /
router-msall-2 ----/
```

The advantage is that the configuration is easier to scale because each VTEP does not need to explicitly configure every other VTEP.

---

# Verification commands

## Check IP configuration

```bash
ip addr
```

## Check VXLAN

```bash
ip -d link show vxlan10
```

Static mode must show something similar to:

```text
vxlan id 10
remote 10.0.0.2
local 10.0.0.1
dev eth0
dstport 4789
```

Multicast mode must show something similar to:

```text
vxlan id 10
group 239.1.1.1
local 10.0.0.1
dev eth0
dstport 4789
```

## Check bridge

```bash
bridge link
```

The bridge must contain:

```text
eth1
vxlan10
```

## Check MAC address table

```bash
bridge fdb show br br0
```

If `brctl` is available:

```bash
brctl showmacs br0
```

The bridge learns MAC addresses from both the local network and the VXLAN network.

---

# Connectivity tests

## Underlay test

From `router-msall-1`:

```bash
ping -c 3 10.0.0.2
```

Expected result:

```text
3 packets transmitted
3 packets received
0% packet loss
```

## VXLAN test

From `host-msall-1`:

```bash
ping -c 3 30.1.1.2
```

Expected result:

```text
3 packets transmitted
3 packets received
0% packet loss
```

The reverse direction can also be tested from `host-msall-2`:

```bash
ping -c 3 30.1.1.1
```

---

# Packet inspection

Packet inspection is mandatory for Part 2.

The capture is performed in GNS3 on the link:

```text
router-msall-1 <-> Switch-msall
```

Useful Wireshark filters:

```text
vxlan
```

or:

```text
udp.port == 4789
```

The capture should show:

```text
Outer Ethernet
    |
Outer IPv4
10.0.0.1 -> 10.0.0.2
    |
UDP
destination port 4789
    |
VXLAN
VNI 10
    |
Inner Ethernet
    |
Inner IPv4
30.1.1.1 -> 30.1.1.2
    |
ICMP
```

This proves that the original Layer 2 traffic is transported through the VXLAN tunnel.

---

# Project export

The GNS3 project is exported as:

```text
badass-p2.gns3project
```

The Docker base images are exported with:

```bash
docker save -o msall-host.tar msall-host:latest
docker save -o msall-router.tar msall-router:latest
```

The final archive is:

```text
badass-p2-final.zip
```

It contains:

```text
badass-p2.gns3project
msall-host.tar
msall-router.tar
static/
multicast/
```

The archive therefore contains:

- the GNS3 project
- the host Docker base image
- the router Docker base image
- the static configuration
- the multicast configuration

---

# Import procedure

To restore the Docker images:

```bash
docker load -i msall-host.tar
docker load -i msall-router.tar
```

Then import the GNS3 project:

```text
File
-> Import project
```

and select:

```text
badass-p2.gns3project
```

The Docker templates can then use:

```text
msall-host:latest
msall-router:latest
```

---

# Summary

The final topology provides a working VXLAN network using:

```text
VNI: 10
Bridge: br0
VXLAN interface: vxlan10
UDP port: 4789
```

Static mode uses:

```text
remote VTEP addresses
```

Multicast mode uses:

```text
group 239.1.1.1
```

The two hosts:

```text
30.1.1.1
30.1.1.2
```

can communicate through the VXLAN tunnel, and packet inspection confirms that the ICMP traffic is encapsulated inside VXLAN.
