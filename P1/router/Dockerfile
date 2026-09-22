FROM frrouting/frr:latest

RUN apk update && apk add --no-cache \
    busybox-extras \
    iproute2 \
    bridge-utils \
    tcpdump

RUN sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons && \
    sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons && \
    sed -i 's/isisd=no/isisd=yes/' /etc/frr/daemons

RUN touch /etc/frr/vtysh.conf /etc/frr/frr.conf && \
    chown -R frr:frr /etc/frr