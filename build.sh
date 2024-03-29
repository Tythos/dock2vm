#!/bin/bash

# 0. Preparing working environment...
echo 0. Preparing working environment...
NAME=dock2vm
OUTPUT=/dev/null # change to /dev/stdout for "verbose"
sudo apt-get update > $OUTPUT
sudo apt-get -y install grub2-common grub-efi-amd64 fdisk qemu-utils > $OUTPUT

# 1. Capturing image filesystem in TAR archive...
echo 1. Capturing image filesystem in TAR archive...
docker build -q -t $NAME . > $OUTPUT
CID=$(docker run -d $NAME /bin/true)
docker export -o $NAME.tar ${CID} > $OUTPUT

# 2. Extracting filesystem to mount folder...
echo 2. Extracting filesystem to mount folder...
OS_PATH=./os
mkdir -p $OS_PATH
tar --numeric-owner --directory=$OS_PATH -xf ./$NAME.tar

# 3. Creating disk image with partition...
echo 3. Creating disk image...
BLOCK_SIZE=512
dd if=/dev/zero of=$NAME.img bs=2097152 count=$BLOCK_SIZE status=none > $OUTPUT
echo "type=83,bootable" | sfdisk $NAME.img > $OUTPUT

# 4. Formatting filesystem within parition...
echo 4. Formatting filesystem within parition...
LOOPDEVICE=$(losetup -f)
losetup -o $(expr $BLOCK_SIZE \* 2048) ${LOOPDEVICE} $NAME.img > $OUTPUT
mkfs.ext4 ${LOOPDEVICE} -q > $OUTPUT

# 5. Copying filesystem to new partition...
echo 5. Copying filesystem to new partition...
MNT_PATH=./mnt
mkdir -p $MNT_PATH
sudo mount -t auto ${LOOPDEVICE} $MNT_PATH
sudo cp -a $OS_PATH/. $MNT_PATH

# 6. Setting up bootloader...
echo 6. Setting up bootloader...
grub-install --boot-directory=$MNT_PATH/boot --target=x86_64-efi /dev/sda > $OUTPUT 2>&1
cp grub.cfg $MNT_PATH/boot/grub/custom.cfg > $OUTPUT
rm $MNT_PATH/.dockerenv > $OUTPUT

# 7. Updating critical filesystem permissions...
echo 7. Updating critical filesystem permissions...
sudo chown root $MNT_PATH/var/empty
sudo chgrp root $MNT_PATH/var/empty
sudo chmod 744 $MNT_PATH/var/empty

# 8. Unmounting and writing master boot record...
echo 8. Unmounting and writing master boot record...
sudo umount $MNT_PATH
losetup -d ${LOOPDEVICE}
dd if=/usr/lib/syslinux/mbr/mbr.bin of=$NAME.img bs=440 count=1 conv=notrunc status=none

# 9. Compress final virtual image file
echo 9. Compress final virtual image file
gzip -k $NAME.img -c > $NAME.img.gz
FINALSIZE_MB=$(expr $(stat -c %s $NAME.img.gz) / 1024 / 1024)
echo Final size: $FINALSIZE_MB MB
