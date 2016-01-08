#!/bin/bash
#http://linux-sunxi.org/Mainline_Debian_HowTo#Boot


#Downloading precompiled U-Boot images

#Download the U-Boot image u-boot-sunxi-with-spl.bin.gz for your hardware from http://d-i.debian.org/daily-images/armhf/daily/u-boot/, i.e. for Cubieboard 1
cd /mnt
export kernel=linux-image-armmp-lpae
#qemu-debootstrap --verbose --include=${kernel},locales,flash-kernel,sunxi-tools,firmware-linux --arch=armhf jessie /mnt http://ftp.debian.org/debian
debootstrap --verbose --include=${kernel},locales,sunxi-tools stretch /mnt http://ftp.debian.org/debian
tar -cvf /tmp/debianbanana20151227clean.tar ./
#with ${kernel} being either linux-image-armmp for Cubieboard 1 or linux-image-armmp-lpae for Cubietruck. For Cubieboard 2, linux-image-armmp-lpae should be the correct kernel. You need to have the package qemu-user-static installed.
#If in doubt, have a look at the Debian wiki or the official documentation.
#Configuring the system

#flash-kernel

#Write extra modules that should be loaded at boot time to /mnt/etc/modules.
 echo "rtc_sunxi" >>  /mnt/etc/initramfs-tools/modules
#This module does not exist for the linux-image-armmp kernels, so it is not available for Cubieboard 1.
#Base configuration files

 echo "/dev/mmcblk0p1  /           ext4    relatime,errors=remount-ro        0       1" > /mnt/etc/fstab
 echo "bananapi" > /mnt/etc/hostname
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
# DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot /mnt dpkg --configure -a
# LC_ALL=C LANGUAGE=C LANG=C chroot /mnt
 chroot /mnt dpkg --configure -a
chroot /mnt
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
apt-get install flash-kernel -y
exit
#We are going to use flash-kernel to generate the boot.src. Tell it which hardware we're aiming for. (Devices listed in: /usr/share/flash-kernel/db/all.db)
mkdir /mnt/etc/flash-kernel/
echo "LeMaker Banana Pi" >> /mnt/etc/flash-kernel/machine
#Kernel arguments:
echo 'LINUX_KERNEL_CMDLINE="console=ttyS0,115200 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x1024p60 root=/dev/mmcblk0p1 rootwait panic=10 ${extra}"' >> /mnt/etc/default/flash-kernel
 chroot /mnt
flash-kernel
   passwd root
wget https://raw.githubusercontent.com/andrewc12/scripts/master/pxe/postinst.sh -O /tmp/postinst.sh
/bin/chmod 755 /tmp/postinst.sh
/tmp/postinst.sh
#Kernel modules

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

















Now you should be able to boot your brand new debian installation. Hopefully it'll boot, pull up networking and you're able to login via ssh.
Manual boot (serial console)

If it doesn't boot, you'll want an 3,3V USB UART module to debug. U-Boot seems to be powerful and gives helpful error messages. If it says something like 'CRC error' 'loading default environment', that's okay, we want default. (Side note: use the filesize variable or give the size in hexadecimal)
 setenv bootargs console=ttyS0,115200n8 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x1024p60 root=/dev/mmcblk0p1 rootwait panic=10 ${extra}
 ext4load mmc 0:1 0x47000000 boot/dtb-3.16.0-4-armmp-lpae
 ext4load mmc 0:1 0x46000000 boot/vmlinuz-3.16.0-4-armmp-lpae
 ext4load mmc 0:1 0x48000000 boot/initrd.img-3.16.0-4-armmp-lpae
 bootz 0x46000000 0x48000000:${filesize} 0x47000000
systemd
Newer debian uses systemd by default. Beside activing ttyS0 there using
systemctl enable serial-getty@ttyS0.service
make sure your kernel has
CONFIG_FHANDLE=y
Also note that semantic of 'halt' is not yet reestablished. Use 'poweroff' instead, meanwhile.
Conclusion

As of now it is possible to run Debian with a recent mainline kernel and only few changes to the system. We can throw away some of the crude, device-specific things like the modifications to the kernel, 'script.bin'... U-Boot is on the right track and Debian-installer will be usable on various sunxi-based systems, once a recent kernel arrives in the installer builds.
What's left to be done is:
Optimizing the system
Getting some/any graphics support
See also

Mainline Kernel Howto
Bootable SD card
External Links

https://wiki.debian.org/InstallingDebianOn/Allwinner
https://github.com/igorpecovnik/Cubietruck-Debian/blob/master/build.sh
Category: Tutorial
Create accountLog inPageDiscussionReadView sourceView history

Search
 Go Search
Navigation
Main page
Community portal
Recent changes
Random page
Help
Tools
What links here
Related changes
Special pages
Printable version
Permanent link
This page was last modified on 20 September 2015, at 16:57.
This page has been accessed 10,760 times.
Content is available under Creative Commons Attribution unless otherwise noted.
Privacy policyAbout linux-sunxi.orgDisclaimersCreative Commons Attribution Powered by MediaWiki