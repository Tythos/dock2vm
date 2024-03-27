#!/bin/bash
LOOP=loop3
# 1. Formatting new image and generated disk partition table...
echo 1. Formatting new image and generated disk partition table...
IMG_SIZE=$(expr 1024 \* 1024 \* 1024)
dd if=/dev/zero of=/os/linux.img bs=${IMG_SIZE} count=1
sfdisk /os/linux.img <<EOF
label: dos
label-id: 0x5d8b75fc
device: new.img
unit: sectors

linux.img1 : start=2048, size=2095104, type=83, bootable
EOF
# 2. Setting up loop device for new ext3 filesystem...
echo 2. Setting up loop device for new ext3 filesystem...
OFFSET=$(expr 512 \* 2048)
losetup -o ${OFFSET} /dev/$LOOP /os/linux.img
mkfs.ext3 /dev/$LOOP
# 3. Mounting device and extracting filesystem...
echo 3. Mounting device and extracting filesystem...
mkdir /os/mnt
mount -t auto /dev/loop0 /os/mnt/
tar -xvf /os/linux.tar -C /os/mnt/ > /dev/null
