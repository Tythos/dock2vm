#!/bin/bash
#
echo 1. Defining parameters...
export UID=$(id -u)
export GID=$(id -g)
export VM_SIZE_SIZE=1024
export NAME=dock2vm
export OS_PATH=./os
export DISK_SIZE=2G
export MNT_PATH=./mnt
export VM_DISK_SIZE_MB=1024
export VM_DISK_SIZE_SECTOR=$(expr $VM_DISK_SIZE_MB \* 1024 \* 1024 / 512)
export OUTPUT=/dev/stdout # for "verbose", set to /dev/stdout; for "quiet", set to /dev/null
#
echo 1. Updating dependencies...
sudo apt-get update
sudo apt-get -y install grub2-common grub-efi-amd64 fdisk qemu-utils
#
echo 1. Building image and dumping filesystem to .TAR archive...
docker build -q -t $NAME .
export CID=$(docker run -d $NAME /bin/true)
docker export -o ./$NAME.tar ${CID}
#
echo 1. Extracting tar archive...
mkdir -p $OS_PATH
tar -C $OS_PATH --numeric-owner -xf ./$NAME.tar
#
echo 1. Creating disk image...
dd if=/dev/zero of=./$NAME.img bs=${VM_DISK_SIZE_SECTOR} count=512
#
echo 1. Making partition...
echo "type=83,bootable" | sfdisk ./$NAME.img
#
echo 1. Formatting partition with ext4...
sudo losetup -D
export LOOPDEVICE=$(losetup -f)
#
echo 1. Setting up loop device...
sudo losetup -o $(expr 512 \* 2048) ${LOOPDEVICE} ./$NAME.img
sudo mkfs.ext4 ${LOOPDEVICE}
#
echo 1. Copying directory structure to partition...
mkdir -p $MNT_PATH
sudo mount -t auto ${LOOPDEVICE} $MNT_PATH
sudo cp -a $OS_PATH $MNT_PATH
#
echo 1. Setting up extlinux...
extlinux --install $MNT_PATH/boot
cp $OS_PATH/syslinux.cfg $MNT_PATH/boot/syslinux.cfg
rm $MNT_PATH/.dockerenv
#
echo 1. Unmounting from device...
umount $MNT_PATH
sudo losetup -D
#
echo 1. Writing syslinux MBR...
dd if=/usr/lib/syslinux/mbr/mbr.bin of=./$NAME.img bs=440 count=1 conv=notrunc
#
echo 1. Converting image to qcow2 format...
qemu-img convert -c ./$NAME.img -O qcow2 $NAME.qcow2
chown $UID:$GID ./$NAME.img $NAME.qcow2
rm -r $OS_PATH
