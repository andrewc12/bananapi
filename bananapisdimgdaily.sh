#!/bin/sh
wget http://d-i.debian.org/daily-images/armhf/20151218-00:32/netboot/SD-card-images/firmware.BananaPi.img.gz
wget http://d-i.debian.org/daily-images/armhf/20151218-00:32/netboot/SD-card-images/partition.img.gz
zcat firmware.BananaPi.img.gz partition.img.gz > firmware.BananaPi+partition.img
