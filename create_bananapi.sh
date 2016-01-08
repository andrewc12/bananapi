#!/bin/bash

           function run_stage {
               
               
               
               
               
               
               
               
               
               
#http://linux-sunxi.org/Mainline_Debian_HowTo#Boot
if [ "$stage" == "first" ]
then
cd /tmp
dd if=/dev/zero bs=1M count=2000 > /tmp/debianbanana20151226.img

losetup -f --show -P /tmp/debianbanana20151226.img


#Downloading precompiled U-Boot images

#Download the U-Boot image u-boot-sunxi-with-spl.bin.gz for your hardware from http://d-i.debian.org/daily-images/armhf/daily/u-boot/, i.e. for Cubieboard 1
 wget http://d-i.debian.org/daily-images/armhf/daily/u-boot/BananaPi/u-boot-sunxi-with-spl.bin.gz
 gunzip u-boot-sunxi-with-spl.bin.gz
#Setting up the SD-card

#${card} is the SD device (ie /dev/sdc). ${partition} is the partition number (ie. 1). Exclamation.png Warning: This will delete the content.
#export card=/dev/mmcblk0
 #export partition=p1
 export card=/dev/loop0
 export partition=p1
 dd if=/dev/zero of=${card} bs=1M count=1
 dd if=u-boot-sunxi-with-spl.bin of=${card} bs=1024 seek=8
#Create partition(s). ie one big partition beginning with sector 2048, type 83 (Linux)
 fdisk ${card}
 mkfs.ext4 ${card}${partition}

 mount ${card}${partition} /mnt
#This will first clean the card (at least the first 1M), install the U-Boot bootloader you compiled/downloaded in the step before, and then you can create -for example- one partition, format it, and mount it to /mnt/ for use in the next steps.
#(Also refer to Bootable_SD_card)
#Bootstrapping Debian

#This will bootstrap Debian stable (aka Jessie)
apt-get install qemu-user-static
fi
if [ "$stage" == "second" ]
then
cd /mnt
fi
export kernel=linux-image-armmp-lpae
#qemu-debootstrap --verbose --include=${kernel},locales,flash-kernel,sunxi-tools,firmware-linux --arch=armhf jessie /mnt http://ftp.debian.org/debian
if [ "$stage" == "first" ]
then
qemu-debootstrap --verbose --include=${kernel},locales,flash-kernel,sunxi-tools --arch=armhf stretch /mnt http://ftp.debian.org/debian
fi
if [ "$stage" == "second" ]
then
debootstrap --verbose --include=${kernel},locales,sunxi-tools stretch /mnt http://ftp.debian.org/debian
tar -cvf /tmp/debianbanana20151227clean.tar ./
fi

#with ${kernel} being either linux-image-armmp for Cubieboard 1 or linux-image-armmp-lpae for Cubietruck. For Cubieboard 2, linux-image-armmp-lpae should be the correct kernel. You need to have the package qemu-user-static installed.
#If in doubt, have a look at the Debian wiki or the official documentation.
#Configuring the system

#flash-kernel

if [ "$stage" == "first" ]
then
#We are going to use flash-kernel to generate the boot.src. Tell it which hardware we're aiming for. (Devices listed in: /usr/share/flash-kernel/db/all.db)
mkdir /mnt/etc/flash-kernel/
echo "LeMaker Banana Pi" >> /mnt/etc/flash-kernel/machine
#Kernel arguments:
echo 'LINUX_KERNEL_CMDLINE="console=ttyS0,115200 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x1024p60 root=/dev/mmcblk0p1 rootwait panic=10 ${extra}"' >> /mnt/etc/default/flash-kernel
#Kernel modules

#Write extra modules that should be loaded at boot time to /mnt/etc/modules.
 echo "rtc_sunxi" >>  /mnt/etc/initramfs-tools/modules
#This module does not exist for the linux-image-armmp kernels, so it is not available for Cubieboard 1.
#Base configuration files

 echo "/dev/mmcblk0p1  /           ext4    relatime,errors=remount-ro        0       1" > /mnt/etc/fstab
 echo "bananapi" > /mnt/etc/hostname
fi
#Add your hostname to the 127.0.0.1 and ::1 lines in /mnt/etc/hosts, e.g.
 nano /mnt/etc/hosts
#Hint: Please consider using your favorite debian-mirror instead of ftp.debian.org.
cat <<EOF > /mnt/etc/apt/sources.list
# 

deb http://ftp.debian.org/debian/ stretch main non-free contrib
deb-src http://ftp.debian.org/debian/ stretch main non-free contrib

deb http://security.debian.org/ stretch/updates main contrib non-free
deb-src http://security.debian.org/ stretch/updates main contrib non-free

EOF
cat <<EOF > /mnt/etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug eth0
iface eth0 inet dhcp
EOF

#Now chroot in to the new system and set everything up.
 mount -t proc chproc /mnt/proc
 mount chsys /mnt/sys -t sysfs
 mount -t devtmpfs chdev /mnt/dev || mount --bind /dev /mnt/dev
 mount -t devpts chpts /mnt/dev/pts
 echo -e '#!/bin/sh\nexit 101' > /mnt/usr/sbin/policy-rc.d
 chmod 755 /mnt/usr/sbin/policy-rc.d
 if [ "$stage" == "first" ]
then
 DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot /mnt dpkg --configure -a
 LC_ALL=C LANGUAGE=C LANG=C chroot /mnt
 fi
 if [ "$stage" == "second" ]
then
# DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot /mnt dpkg --configure -a
# LC_ALL=C LANGUAGE=C LANG=C chroot /mnt
 chroot /mnt dpkg --configure -a
chroot /mnt
fi
#The next steps are executed inside the chroot:
   dpkg-reconfigure locales
   dpkg-reconfigure tzdata
#Optional: Install U-Boot (U-Boot from debian is not used, but it does no harm and i'll include it for future reference)
          apt-get update
          apt-get install firmware-linux
   apt-get install u-boot u-boot-tools
#Or, if you want simple frame-buffer support (on some cards) go with kernel >3.19. For this, you need to add experimental sources for apt:
#   apt-get -t experimental install linux-image-3.19.0-trunk-armmp-lpae u-boot u-boot-tools
#Install non-free firmware and add one currently missing file to the wifi-firmware (not for Cubieboard 1):
#   apt-get install firmware-brcm80211
#   wget -O /lib/firmware/brcm/brcmfmac43362-sdio.txt http://dl.cubieboard.org/public/Cubieboard/benn/firmware/ap6210/nvram_ap6210.txt
#Install a few other things:
   apt-get install console-setup keyboard-configuration openssh-server ntp samba nfs-kernel-server lxc bridge-utils debootstrap btrfs-tools -y
      apt-get install ca-certificates  -y                  
   apt-get install ntpdate  -y       
#At this point, debian should have generated a kernel image /boot/vmlinuz-??? and an initrd /boot/initrd.img-??? for you. Generate the /boot/boot.scr, set a password and after a little cleanup you're set:
if [ "$stage" == "second" ]
then
apt-get install flash-kernel -y
exit
#We are going to use flash-kernel to generate the boot.src. Tell it which hardware we're aiming for. (Devices listed in: /usr/share/flash-kernel/db/all.db)
mkdir /mnt/etc/flash-kernel/
echo "LeMaker Banana Pi" >> /mnt/etc/flash-kernel/machine
#Kernel arguments:
echo 'LINUX_KERNEL_CMDLINE="console=ttyS0,115200 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x1024p60 root=/dev/mmcblk0p1 rootwait panic=10 ${extra}"' >> /mnt/etc/default/flash-kernel
 chroot /mnt
fi

flash-kernel
   passwd root
wget https://raw.githubusercontent.com/andrewc12/scripts/master/pxe/postinst.sh -O /tmp/postinst.sh
/bin/chmod 755 /tmp/postinst.sh
/tmp/postinst.sh
   exit

   #Prepare Login

#Remember: We won't have any display output, so we can eiter: spawn a login on the serial console:
#echo "T0:23:respawn:/sbin/getty -L ttyS0 115200 vt100" >> /mnt/etc/inittab
#and/or use ssh. Since debian disabled root password-login in jessie, re-enable it:
 #sed -i "s/^PermitRootLogin without-password/PermitRootLogin yes/" /mnt/etc/ssh/sshd_config
#or copy your key:
# umask 077; mkdir /mnt/root/.ssh/ cat ~/.ssh/id_rsa.pub >> /mnt/root/.ssh/authorized_keys
#chroot and setup

   
#Cleanup

 rm /mnt/usr/sbin/policy-rc.d
 rm /mnt/usr/bin/qemu-arm-static
 umount /mnt/dev/pts && umount /mnt/dev && umount /mnt/sys && umount /mnt/proc && umount /mnt
 sync
#Boot

if [ "$stage" == "second" ]
then
cd /mnt
tar -cvf /tmp/debianbanana20151227.tar ./
 
 
 
 cd /tmp
dd if=/dev/zero bs=1M count=1000 > /tmp/debianbanana20151227.img

losetup -f --show -P /tmp/debianbanana20151227.img


#Downloading precompiled U-Boot images

#Download the U-Boot image u-boot-sunxi-with-spl.bin.gz for your hardware from http://d-i.debian.org/daily-images/armhf/daily/u-boot/, i.e. for Cubieboard 1
 wget http://d-i.debian.org/daily-images/armhf/daily/u-boot/BananaPi/u-boot-sunxi-with-spl.bin.gz
 gunzip u-boot-sunxi-with-spl.bin.gz
#Setting up the SD-card

#${card} is the SD device (ie /dev/sdc). ${partition} is the partition number (ie. 1). Exclamation.png Warning: This will delete the content.
#export card=/dev/mmcblk0
 #export partition=p1
 export card=/dev/loop0
 export partition=p1
 dd if=/dev/zero of=${card} bs=1M count=1
 dd if=u-boot-sunxi-with-spl.bin of=${card} bs=1024 seek=8
#Create partition(s). ie one big partition beginning with sector 2048, type 83 (Linux)
 fdisk ${card}
 mkfs.ext4 ${card}${partition}

 mount ${card}${partition} /mnt
cd /mnt
tar -xvf /tmp/debianbanana20151227.tar ./
cd /tmp

 umount /mnt
 losetup -d /dev/loop0
 sync
gzip debianbanana20151227.img
fi               
               
               
               
               
               
               
               
               
               
           }

   # Reset all variables that might be set
stage=
 
 while :; do
     case $1 in
         first)   # Call the first stage, then exit.
             stage="first"
             run_stage
             exit
             ;;
         second)   # Call the second stage, then exit.
             stage="second"
             run_stage
             exit
             ;;
        *)               # Default case: If no more options then break out of the loop.
     printf 'ERROR: "$0" requires a non-empty argument.\n' >&2
                   exit 1
     esac
done

