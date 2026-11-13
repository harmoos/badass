#!/bin/sh

# Start FRRouting daemons enabled in /etc/frr/daemons
/usr/lib/frr/frrinit.sh start

# Keep the Docker container alive for GNS3
exec tail -f /dev/null
