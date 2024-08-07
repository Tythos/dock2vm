#!/bin/bash
#
echo 1. Defining parameters...
export NAME=dock2vm
export OS_PATH=./$NAME.dir
export DISK_SIZE=2G
export MNT_PATH=./mnt
export VM_DISK_SIZE_MB=1024
export VM_DISK_SIZE_SECTOR=$(expr $VM_DISK_SIZE_MB \* 1024 \* 1024 / 512)
export OUTPUT=/dev/stdout # for "verbose", set to /dev/stdout; for "quiet", set to /dev/null
#
echo 1. Updating dependencies, building image filesystem...
sudo apt-get update
sudo apt-get -y install grub2-common grub-efi-amd64 fdisk qemu-utils
#
echo 1. Building image and caching filesystem via intermediate .TAR archive...
docker build -q -t $NAME .
export CID=$(docker run -d $NAME /bin/true)
docker export -o ./$NAME.tar $CID
mkdir -p $OS_PATH
tar -C $OS_PATH --numeric-owner -xf ./$NAME.tar
#
echo 1. Creating disk image and paritioning...
dd if=/dev/zero of=./$NAME.img bs=$VM_DISK_SIZE_SECTOR count=512
echo "type=83,bootable" | sfdisk ./$NAME.img
#
echo 1. Formatting with ext4 via loop device...
sudo losetup -D
export LOOPDEVICE=$(losetup -f)
sudo losetup -o $(expr 512 \* 2048) $LOOPDEVICE ./$NAME.img
sudo mkfs.ext4 $LOOPDEVICE
#
echo 1. Copying directory structure to partition...
mkdir -p $MNT_PATH
sudo mount -t auto $LOOPDEVICE $MNT_PATH
sudo cp -a $OS_PATH/. $MNT_PATH
#
echo 1. Setting global and filesystem permissions...
sudo chown -R root:root $MNT_PATH
sudo chmod -R u+rwX,go+rX,go-w $MNT_PATH
sudo chmod -R 777 $MNT_PATH/var/lib
sudo chmod -R 777 $MNT_PATH/etc/cloud
#
echo 1. Setting up extlinux w/ boot config...
sudo extlinux --install $MNT_PATH/boot
sudo cp syslinux.cfg $MNT_PATH/boot/syslinux.cfg
sudo cat ./fstab >> $MNT_PATH/etc/fstab
sudo rm $MNT_PATH/.dockerenv
#
echo 1. Unmounting devices, writing MBR, converting image...
sudo umount $MNT_PATH
sudo losetup -D
dd if=/usr/lib/syslinux/mbr/mbr.bin of=./$NAME.img bs=440 count=1 conv=notrunc
qemu-img convert -c ./$NAME.img -O qcow2 ./$NAME.qcow2
#
echo 1. Cleaning up interim artifacts...
sudo rm -rf $OS_PATH
sudo rm -rf $MNT_PATH
rm *.img
rm *.tar
