#!/bin/bash
#
echo 1. Preparing working environment...
export NAME=dock2vm
export OUTPUT=/dev/stdout # for "verbose", set to /dev/stdout; for "quiet", set to /dev/null
sudo apt-get update > $OUTPUT
sudo apt-get -y install grub2-common grub-efi-amd64 fdisk qemu-utils > $OUTPUT
#
echo 1. Capturing image filesystem in TAR archive...
docker build -q -t $NAME . > $OUTPUT
export CID=$(docker run -d $NAME /bin/true)
docker export -o $NAME.tar ${CID} > $OUTPUT
#
echo 1. Extracting filesystem to mount folder...
export OS_PATH=./os
mkdir -p $OS_PATH
tar --numeric-owner --directory=$OS_PATH -xf ./$NAME.tar
#
echo 1. Creating disk image...
export DISK_SIZE=2G
dd if=/dev/zero of=$NAME.img bs=1M count=$(expr $DISK_SIZE \* 1024) status=none > $OUTPUT
#
echo 1. Attaching loop device to the disk image...
export LOOPDEVICE=$(sudo losetup -f)
sudo losetup ${LOOPDEVICE} $NAME.img > $OUTPUT
#
echo 1. Partitioning disk image using the loop device...
sudo parted ${LOOPDEVICE} --script mklabel gpt
sudo parted ${LOOPDEVICE} --script mkpart ESP fat32 1MiB 261MiB
sudo parted ${LOOPDEVICE} --script set 1 esp on
sudo parted ${LOOPDEVICE} --script mkpart primary ext4 261MiB 100%
sudo partprobe ${LOOPDEVICE}
export LOOPDEVICE1=$(sudo losetup -f --show --offset $((1 * 1024 * 1024)) --sizelimit $((260 * 1024 * 1024)) ${LOOPDEVICE})
export LOOPDEVICE2=$(sudo losetup -f --show --offset $((261 * 1024 * 1024)) ${LOOPDEVICE})
#
echo 1. Formatting partitions...
sudo mkfs.vfat -F 32 -n EFI ${LOOPDEVICE1} > $OUTPUT
sudo mkfs.ext4 -L root ${LOOPDEVICE2} -q > $OUTPUT
#
echo 1. Mounting and copying files...
export MNT_PATH=./mnt
mkdir -p $MNT_PATH
sudo mount ${LOOPDEVICE2} $MNT_PATH
sudo mkdir -p $MNT_PATH/boot/efi
sudo mount ${LOOPDEVICE1} $MNT_PATH/boot/efi
sudo cp -a $OS_PATH/* $MNT_PATH/
#
echo 1. Setting up bootloader...
sudo grub-install --boot-directory=$MNT_PATH/boot --target=x86_64-efi --efi-directory=$MNT_PATH/boot/efi --removable ${LOOPDEVICE} > $OUTPUT 2>&1
sudo cp grub.cfg $MNT_PATH/boot/grub/custom.cfg > $OUTPUT
sudo rm $MNT_PATH/.dockerenv > $OUTPUT
#
echo 1. Updating critical filesystem permissions...
sudo chown root:root $MNT_PATH/var/empty
sudo chmod 744 $MNT_PATH/var/empty
#
echo 1. Unmounting and writing master boot record...
sudo umount $MNT_PATH/boot/efi
sudo umount $MNT_PATH
sudo losetup -d ${LOOPDEVICE1}
sudo losetup -d ${LOOPDEVICE2}
sudo losetup -d ${LOOPDEVICE}
sudo dd if=/usr/lib/syslinux/mbr/mbr.bin of=$NAME.img bs=440 count=1 conv=notrunc status=none
#
echo 1. Compress final virtual image file...
gzip -k $NAME.img -c > $NAME.img.gz
export FINALSIZE_MB=$(expr $(stat -c %s $NAME.img.gz) / 1024 / 1024)
echo Final size: $FINALSIZE_MB MB
