#!/bin/sh

BBVERSION="1-26.2"

usage () {
    echo "usage: $0 <busybox-dir> [options] ..."
    echo
    echo "creates a rootfs at ./root/rootfs.cpio and puts the <busybox-dir>/busybox binary in it"
    echo
    echo "where [options] are any one of"
    echo
#    echo "dynamic       setup for building dynamically"
    echo "getty         use getty instead of ash"
#    echo "fuse          use FUSE instead of mount(1)"
    exit 1
}

if [ ! "$1" ]; then
    echo "error: <directory> not set; run '$0 -h' for usage"
    exit 1
fi

BBROOT="$1"
shift

if [ -e "root" ]; then
    echo "error: ./root directory already exists"
    exit 1
fi

mkdir root
cd root
mkdir -p bin etc dev lib proc sbin sys tmp usr usr/bin usr/lib usr/sbin
cd ..
cp $BBROOT/busybox root/bin/
cd root

#if [ "$*" = "dynamic" ]; then
#echo "dyn"
#    if [ $(ldconfig -p | grep libc.so.6) ]; then
#        echo "libc.so.6 required"
#    fi
#    if [ $(ldconfig -p | grep ld.so.1) ]; then
#        echo "ld.so.1 required"
#    fi

#    cp $RISCV/build/sysroot64/lib/libc.so.6 lib/
#    cp $RISCV/build/sysroot64/lib/ld.so.1 lib/
#    cd $BBROOT/busybox-$BBVERSION
#    sed -i 's/CONFIG_STATIC=y/# CONFIG_STATIC is not set/' .config
#fi

if [ "$*" = "getty" ]; then
echo "getty"
    CONSOLE=":respawn:/bin/busybox getty 38400 ttyHTIF0"
else
    CONSOLE="/dev/console::sysinit:-/bin/ash"
fi

echo "::sysinit:/bin/busybox mount -t proc proc /proc
::sysinit:/bin/busybox mount -t tmpfs tmpfs /tmp
::sysinit:/bin/busybox mount -o remount,rw /dev/htifblk0 /
::sysinit:/bin/busybox --install -s" "$CONSOLE" > etc/inittab


ln -s ../bin/busybox init

sudo mknod dev/console c 5 1
find . | cpio --quiet -o -H newc > rootfs.cpio

exit 0

#dd if=/dev/zero of=root.bin bs=1M count=64
#mkfs.ext2 -F root.bin

#mkdir mnt

#if [ "$@" = "fuse" ]; then
#    fuseext2 -o rw+ root.bin mnt
#    fusermount -u mnt
#else
#    mount -o loop root.bin mnt
#    umount mnt
#fi

