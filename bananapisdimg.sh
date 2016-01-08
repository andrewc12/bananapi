#!/bin/sh
wget http://ftp.uk.debian.org/debian/dists/stretch/main/installer-armhf/current/images/netboot/SD-card-images/firmware.BananaPi.img.gz
wget http://ftp.uk.debian.org/debian/dists/stretch/main/installer-armhf/current/images/netboot/SD-card-images/partition.img.gz
zcat firmware.BananaPi.img.gz partition.img.gz > firmware.BananaPi+partition.img
